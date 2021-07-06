---
layout: post
title: Azure Monitor Log Analytics too Expensive? Part 2 - Save Some Money
categories: [Blog]
tags: [azure,devops]
---

This is the second post of a two part blog post on Log Analytics cost analysis and savings:

**[Part 1 - Find Out Why](https://trstringer.com/log-analytics-expensive-part-1-discovery/)**
- What costs money in Log Analytics?
- What is taking up all the data in my workspace?
- How can I find the root consumption sources?

**Part 2 - Save Some Money**
- Tune data ingestion and retention
- Take advantage of the commitment tiers
- Other workspace strategies

In the first post we talked about how to get details of why your workspace is so expensive. Now in this post we'll discuss about how to lessen those costs with a few strategies.

## Log less data

As we talked about in the last post, one of the costs that you incur with Azure Monitor Log Analytics is data ingestion. When setting up your logging, it's usually quite easy to just "select all the boxes". But that directly translates to more data, and then more money. A good exercise is to go through your agents and monitoring settings and see exactly what you are logging. Should you be logging this at all?

Another way to reduce log data is to **change the log level**. Do you need debug logs in your workspace? Usually the lower the log level, the higher the amount of logs. Understand your requirements and don't over-log unnecessarily. But what happens if you have an outage or something you need to troubleshoot? Nothing better than those debug logs! Perhaps create a process to hot set the log level lower (e.g. to debug) temporarily so that you can collect more verbose logs short term.

## Shorter retention time...

If you're storing your data in a Log Analytics workspace for more than 31 days, you're paying for that. Do you need your logs for 31+ days? If not, change the data retention to go back to the free setting.

## ...or offload logs to cheaper storage

If you *do* need logs for longer than 31 days, there are other ways to optimize the cost. Something you can do is create a data export rule to have Azure Monitor send logs to an Azure Storage account, and then change your Log Analytics workspaces retention to the free setting. If/when you need the logs from over 31 days, you can just pull them from Azure Storage. Retaining your logs in cheaper storage can help save a *lot*. Read more about [how to export data from a workspace here](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/logs-data-export). There's about an **80% cost savings of storing the log data in the Hot tier of Storage** compared to keeping it in Log Analytics for more than 31 days.

*Note: Currently there is no cost to export data from Azure Monitor. Even when there is a charge, though, exporting data is much cheaper than retaining data. For example, in East US there is a data export fee of $0.10 per GB. To retain the same GB of data would be $0.10 every month.*

## Use the commitment tier pricing

In my experience, I've found that log data is one of the more predictable data streams. It's quite common to have a good estimate (and growth trend) of how much logging your workloads generate. Take advantage of that estimate and save some money! Azure Monitor offers commitment tier pricing, as opposed to the default pay-as-you-go. **By committing to a fixed data size, you can save anywhere from 15-30%**.

Take a look at the [Azure Monitoring pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/) page for specifics on the different commitment tiers, and how much the savings can be.

## Use fewer workspaces

If you're using the commitment tier pricing model like mentioned above, it is cost effective to have fewer workspaces. Per workspace the price per GB goes *down* as you commit to more data. For example, if you have 5 workspaces that you commit to 100 GB/day you will spend $980 at a cost of $1.96 per GB. But if you combine those 5 workspaces into a single workspace with a commitment of 500 GB/day you will spend $865, which is $1.73 per GB. That's about a **12% savings just from consolidating commitment tier workspaces**.

The other benefit of fewer workspaces is that it is easier to query correlated data in a single workspace.

*Note: The consideration of using fewer workspaces also comes with security and access. Before consolidating workspaces, understand these aspects of your organization and requirements.*

## Caution on creating your own solution

As a final note, it's a common thought to create your own logging solution that may be cheaper upfront than using Azure Monitor but I'd like to caution you against this. The cost of creating, setting up, and managing a custom logging solution can accumulate *quickly*. And what happens when your custom solution stops working? Would you get an alert, or just be surprised when you're troubleshooting an actual issue just to find you have zero logs?

The cost of a custom solution is more than you think.

## Summary

I really do like the Azure Monitor experience. I think it's a really great platform for all things monitoring and observability, and with a little planning and consideration it can be cost effective as well!
