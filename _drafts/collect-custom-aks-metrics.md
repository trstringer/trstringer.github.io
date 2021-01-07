---
layout: post
title: Collect Custom Metrics in AKS
categories: [Blog]
tags: [kubernetes,azure,aks,devops,prometheus]
---

Part of running a production-quality Kubernetes cluster is being able to monitor it, and that of course holds true with an Azure Kubernetes Service (AKS) cluster as well. One of the nice things about having your Kubernetes cluster in Azure is a lot of things, including monitoring, is not much harder to setup than a few switches.

Metrics are one part of an effective monitoring strategy (read here for info about [Logging to Azure from an AKS Cluster](https://trstringer.com/native-azure-logging-aks/)), but a very critical one. Metrics allow you to have insight into how your software and systems are running, from alerting to dashboards that look like this:

![AKS metrics dashboard](../images/aks-monitoring-2.png)

That dashboard looks great, but it's just the visual representation of a few KQL queries against the logged custom/app metrics data!

This blog post will show you how to go from a plain AKS cluster all the way to custom metrics.

## How AKS does custom metrics

```
$ curl -o monitoring-config.yaml https://aka.ms/container-azm-ms-agentconfig
```

Modify `monitor_kubernetes_pods` to `true`. Apply the config map.
