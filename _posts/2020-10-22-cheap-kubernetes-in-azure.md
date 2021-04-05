---
layout: post
title: Run Kubernetes in Azure the Cheap Way
categories: [Blog]
tags: [azure, kubernetes, aks, devops]
---

**Update: Since writing this blog post, I have found that [you can save another few dollars by using a Basic SKU load balancer](https://trstringer.com/cheap-aks-load-balancer/)!**

*Note: This blog post is intended **only** for non-production Kubernetes workloads (learning/dev/test).*

Kubernetes is awesome. It's the wave of the future. There's no denying its capabilities and the role it currently plays, and will play, in the software world. And just like any technology, we need to **learn** Kubernetes: How to set it up, how to run software on it, how to break it, how to fix it, etc.

Learning and testing is great, but the brutal reality of Kubernetes is that running it *is not free*. In fact, when we refer to instances of Kubernetes, we call them "clusters". That word sounds... expensive.

Oftentimes when we are learning and experimenting with a technology on our own time, it is typically funded by our own personal money. So that begs the question... **what is the cheapest way to run Kubernetes?** I chose Azure as my platform to run my Kubernetes for a few reasons:

1. I wanted to use a cloud provider to utilize "cloud Kubernetes" features.
1. Azure is the platform that I live in.
1. Azure Kubernetes Service (AKS) itself is **free**, which is a great start to running cheap Kubernetes.

## Node count

One. That's it. You only need a single agent node in your cluster for learning, experimenting, development, and testing.

## Node size

Node size isn't as easy as node count. I wanted to find the cheapest VM size that I could run in AKS. After extensive research and pricing, the most inexpensive allowable VM size in AKS is **Standard_B2s**. You can [read the documentation to understand why B-series VMs are cost-effective for our scenario](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable).

But we can't just stop at VM size! The same VM size has a price that varies between different regions. So after analyzing all regions for this VM size, the cheapest regions are tied at **$0.0416/hour** (at the writing of this blog post). These regions are:

* East US
* East US 2
* North Central US
* West US 2

So randomly picking one for my cluster, I chose East US 2.

## Create the cluster

So now that we have the cluster specs, we can create the AKS cluster:

```
$ az group create --location eastus2 --name <resource_group>
$ az aks create \
    --resource-group <resource_group> \
    --name <aks> \
    --location eastus2 \
    --node-count 1 \
    --node-vm-size "Standard_B2s"
```

## Cost of the running cluster

We've figured out how to create and run the cheapest possible AKS cluster, but we still don't know exactly how much it costs yet. What I did was run the cluster for an entire week. Here is the 7-day cost, broken down by resource type and aggregated at the resource group level (the `mc_*` resource group is where the compute resources for AKS are create. This is called the node resource group).

![Weekly cost of the running AKS cluster](/images/aks-cheap-on.png)

To run this AKS cluster it costs about **$13.22 per week**. The daily cost is about **$1.89 per day**.

## Stop your cluster

The typical use-case for this Kubernetes cluster is most likely learning, experimenting, testing, and other manual interaction workloads. So if you aren't using the cluster, you should stop it! AKS just recently introduced a new feature to [stop and start a Kubernetes cluster](https://docs.microsoft.com/en-us/azure/aks/start-stop-cluster). This is a great way to save money when we aren't using the cluster.

To stop the cluster, it is as easy as running:

```
$ az aks stop \
    --resource-group <resource_group> \
    --name <aks>
```

*Note: Even better/cheaper is to delete your cluster over long periods of not using it. Of course, this assumes that you don't have artifacts or ongoing workloads/experiments in the cluster that you want to preserve.*

## Cost of the stopped cluster

So what does this cluster cost if it is stopped? Just like with the running cluster, I priced out what the stopped cluster costs over the span of a week:

![Weekly cost of the stopped AKS cluster](/images/aks-cheap-off.png)

The stopped cluster only costs **$4.05 per week**. That's only **$0.58 per day**!

## Cost summary

Depending on your usage, this cluster should cost anywhere from **$0.58 to $1.89 daily**.

## Automatically stop your cluster

One of the money-saving techniques in this blog post is stopping your AKS cluster when you aren't using it. Solutions can vary for this, but as a Linux user I like to use systemd services to handle this automatically. If I'm shutting down my computer, I want to make sure I'm also shutting down my AKS cluster.

I'll first create the shell script to handle the cluster shutdown:

**stop-aks-if-running.sh**

```bash
#!/bin/bash

RESOURCE_GROUP="$1"
CLUSTER="$2"
if [[ -z "$CLUSTER" || -z "$RESOURCE_GROUP" ]]; then
	echo "stop-aks-if-running.sh <resource_group> <cluster>"
	exit 1
fi

POWERSTATE=$(az aks show \
	--resource-group "$RESOURCE_GROUP" \
	--name "$CLUSTER" \
	--query "powerState.code" -o tsv)

if [[ "$POWERSTATE" -eq "Running" ]]; then
	az aks stop \
		--resource-group "$RESOURCE_GROUP" \
		--name "$CLUSTER" \
		--no-wait
fi
```

And I want to make sure this runs when I shutdown my machine.

**aks-stop.service**

```
[Unit]
Description=Stop trstringeraks1 service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStop=/usr/bin/bash \
    /usr/local/bin/stop-aks-if-running.sh \
    <resource_group> \
    <aks>

[Install]
WantedBy=multi-user.target
```

This solution gives me a little safety net to make sure I'm not wasting money while my AKS cluster is running and I'm not using it!

## Summary

Hopefully this blog post has showed you that you can, in fact, run a Kubernetes cluster in Azure for **very** little money (relatively speaking). So if you're ready to learn, experiment, or test Kubernetes you should get started today!
