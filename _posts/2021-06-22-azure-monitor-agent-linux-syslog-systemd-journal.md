---
layout: post
title: Using the Azure Monitor Agent to Send systemd Journal Logs through Syslog
categories: [Blog]
tags: [azure,linux,systemd,devops]
---

I [recently talked about sending systemd journal logs to Azure Monitor](https://trstringer.com/systemd-journal-to-syslog-azure-monitoring/), and that blog post focused on using the OMS agent to collect logs from a systemd unit and send them to Azure Monitor through syslog.

But wait... OMS agent seems to work great. Why is there another agent (Azure Monitor Agent) to accomplish, what seems like, the same exact thing? I really like [this blog post explaining what AMA is looking to accomplish (Microsoft Tech Community)](https://techcommunity.microsoft.com/t5/azure-monitor/a-powerful-agent-for-azure-monitor-and-a-simpler-world-of-data/ba-p/2443285). Here are a few quotes from that post (bolded for emphasis):

> It [Azure Monitor Agent] is **meant to replace all other agents that exist today for a similar purpose**, consolidating their features and providing more capabilities on top and enabling long-requested asks by all of you.

So there you have it: AMA is the future.

> it's [Azure Monitor Agent] meant to be the **single agent for uploading data to Azure Monitor** going forward, which collects telemetry data and sends it to Azure Monitor Logs or Metrics (today), and Event Hubs, Storage Accounts and many other destinations that you need to send telemetry data to (in future).

It looks like this is meant to be a single agent with a lot of extensibility. And from my experimentations with [Data Collection Rules (Microsoft docs)](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/data-collection-rule-overview) it seems like just that: a very modularized approach to monitoring.

Now let's see what the exact same scenario from the previous blog post that used OMS agent to accomplish this monitoring requirement. If you remember, we have a systemd unit that logs to the `local4` facility. This unit is unchanged from the previous blog post:

**svc1.service**

```
[Unit]
Description=Testing syslog to log analytics

[Service]
ExecStart=/bin/bash -c "while true; do echo Some info messages; echo '<3>This is a problem!'; sleep 10; done"
SyslogFacility=local4
SyslogIdentifier=syslogazuremonitor
```

Now we want to get these log entries from this unit to Azure Monitor. Let's try with the new Azure Monitor Agent!

Looking at the [prerequisites for the Azure Monitor Agent (Microsoft docs)](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-install?tabs=ARMAgentPowerShell%2CPowerShellWindows%2CPowerShellWindowsArc%2CCLIWindows%2CCLIWindowsArc#prerequisites), the first requirement for an existing Azure Linux VM is to make sure that we have a system managed identity:

```
$ az vm identity assign \
    --resource-group rg1 \
    --name vm1
```

Then we need to install the AMA extension on the VM:

```
$ az vm extension set \
    --name AzureMonitorLinuxAgent \
    --publisher Microsoft.Azure.Monitor \
    --ids $(az vm show \
        --resource-group rg1 \
        --name vm1 \
        --query id -o tsv)
```

Once the AMA extension is set, we can now create the Data Collection Rule (DCR), which will instruct Azure Monitor *which* logs to collect and *where* to send them:

```
$ az monitor data-collection rule create \
    --resource-group rg1 \
    --name dcr1 \
    --data-flow \
        streams="Microsoft-Syslog" \
        destinations="logAnalytics1" \
    --log-analytics \
        resource-id=$(az monitor log-analytics workspace show \
            --resource-group rg1 \
            --workspace-name workspace1) \
        name="logAnalytics1" \
    --syslog \
        name="syslog1" \
        streams="Microsoft-Syslog" \
        facility-names="local4" \
        log-levels="Debug" \
        log-levels="Info" \
        log-levels="Notice" \
        log-levels="Warning" \
        log-levels="Error" \
        log-levels="Critical" \
        log-levels="Alert" \
        log-levels="Emergency"
```

Now that we've created the DCR which tells us what logs to collect and where to send them, we need to associate this DCR with our VM:

```
$ az monitor data-collection rule association create \
    --name association1 \
    --rule-id $(az monitor data-collection rule show \
        --resource-group rg1 \
        --name rule1 \
        --query id -o tsv) \
    --resource $(az vm show \
        --resource-group rg1 \
        --name vm1 \
        --query id -o tsv)
```

Our VM is now tied to the DCR. And that's it! Now you should start seeing the logs of `svc1.service` in the Log Analytics workspace:

```
Syslog
| where Facility == "local4"
| where ProcessName == "syslogazuremonitor"
| project TimeGenerated, Computer, Facility, SeverityLevel, SyslogMessage, ProcessName
| sort by TimeGenerated desc
```

Should you switch from OMS agent to the Azure Monitor Agent? Here's a [great overview on helping make that decision (Microsoft docs)](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview#should-i-switch-to-azure-monitor-agent). Also, you will want to check the [support matrix for AMA before moving forward (Microsoft docs)](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/agents-overview#linux)!

This is a really great solution and one of the big benefits is that I didn't have to log into the Linux VM to configure anything (rsyslog, etc.). It just worked. Really excited to see where this new Azure Monitor Agent and Data Collection Rules go in the future!
