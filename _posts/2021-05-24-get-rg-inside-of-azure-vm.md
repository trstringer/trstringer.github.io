---
layout: post
title: Find the Owning Resource Group From Within an Azure VM
categories: [Blog]
tags: [azure]
---

Have you been working with/in an Azure VM, and you want to know where exactly this VM lives? What resource group? Or if you have a multi-subscription organization, you might not even know which *subscription* that this VM lives in.

It could be a rough task to search through all resources and resource groups to locate this VM. But you can take advantage of the Azure [Instance Metadata Service (IMDS)](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/instance-metadata-service). IMDS is typically used during the provisioning and configuration of an Azure VM, but you can access a lot of helpful information directly even afterwards.

Back to the original reason for this post. IMDS gives you the necessary information from within the Azure VM to be able to locate it within the subscription/resource group. Here's how you can access it from **within the Azure VM**:

```
$ curl -sL -H "metadata:true" "http://169.254.169.254/metadata/instance?api-version=2020-09-01"
```

There is quite a bit of output there, so if you want to just get the VM name, resource group, and subscription ID you can pipe it through `jq`:

```
$ <above_command> | jq "{name:.compute.name,resourceGroupName:.compute.resourceGroupName,subscriptionId:.compute.subscriptionId}"
```

The output will be:

```json
{
  "name": "vm_name",
  "resourceGroupName": "rg_name",
  "subscriptionId": "sub_id"
}
```

And just like that, no need to go searching through your subscription(s) for this VM!
