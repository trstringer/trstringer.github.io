---
layout: post
title: Create an AKS Cluster with Azure Bicep
categories: [Blog]
tags: [azure,kubernetes,aks,devops]
---

The ability to define your infrastructure in code, as opposed to using a GUI, is a very powerful and efficient approach. Typically you will see that named, appropriately, **infrastructure-as-code** (IaC). With Azure resources, there are many ways to accomplish this. If I'm doing some ad-hoc development or testing, I'll typically utilize the Azure CLI.

But when managing infrastructure at scale, it's best to use IaC that is declarative and idempotent. This will allow us to ensure that we can repeatedly and repeatably apply our infrastructure. What does that mean? Well, if you run `az aks create` twice with the same exact cluster name and resource group you will receive an error that it already exists. Sure, you could program in some logic to check resources but that is an imperative way of handling this infrastructure logic.

Instead you can use something that is specifically designed for this: Azure Bicep. In this post I'm going to show how you can create an Azure Kubernetes Service (AKS) cluster with Azure Bicep.

**aks-deployment.bicep**

```
targetScope = 'subscription'

param location string = 'eastus'
param resourcePrefix string = 'aksbicep1'

var resourceGroupName = '${resourcePrefix}-rg'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module aks './aks-cluster.bicep' = {
  name: '${resourcePrefix}cluster'
  scope: rg
  params: {
    location: location
    clusterName: resourcePrefix
  }
}
```

Here we define the entrypoint Bicep template which is a subscription-level scope. We need to start at the subscription level if we want to create a resource group. All this template does is define a couple of parameters (with defaults). It also defines a resource group. Finally it defines a module (see below) that will be the actual AKS cluster resource. We specify that with `module` (as opposed to the direct `resource` like with the resource group definition).

Now we need to specify the AKS cluster, which is at the resource group scope:

**aks-cluster.bicep**

```
param location string
param clusterName string

param nodeCount int = 3
param vmSize string = 'standard_d2s_v3'

resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: '${clusterName}ap1'
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
      }
    ]
  }
}
```

This sample Bicep template would create an AKS cluster with RBAC enabled and a single agent pool that defaults to three nodes with a VM size of standard_d2s_v3. This is just an example for this blog post, but I recommend that you look at the [AKS cluster reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?tabs=bicep) for understanding what the different options are when defining this cluster.

## Validate the Bicep template

Before attempting to create (or update) the resources, it's a good idea to validate the template(s) to make sure they have correct syntax.

```
$ az deployment sub validate \
    --template-file ./aks-deployment.bicep \
    --location eastus
```

If the template is correct, you'll get a JSON output of the deployment. Otherwise, you'll get some helpful error messages showing you what is wrong with your Bicep template(s).

## What will happen *if* you deploy?

I love this feature. Instead of just running the deployment, you can do a **what if** to see what will change if you run the actual deployment.

```
$ az deployment sub create \
    --template-file ./aks-deployment.bicep \
    --location eastus \
    --what-if
```

By specifying `--what-if` (or just `-w` for short), Azure will tell us if resources will be created or otherwise.

## Create the cluster

To create the cluster we will now create the deployment. It's the exact same command as above without `--what-if`:

```
$ az deployment sub create \
    --template-file ./aks-deployment.bicep \
    --location eastus
```

After a short time, the cluster (and resource group) should get created successfully! You'll see the deployment output upon completion. Now your cluster is ready to be used!

## Summary

Utilizing a declarative approach to IaC is a great way to manage your infrastructure. Azure provides Bicep, which is a modern solution to help solve these difficult problems. Being able to create an manage our AKS clusters through Bicep gives us a quick and powerful way to work with our Kubernetes clusters!
