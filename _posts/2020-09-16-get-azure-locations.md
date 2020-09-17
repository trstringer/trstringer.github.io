---
layout: post
title: Search Through Azure Locations and Their Names
categories: [Blog]
tags: [azure]
---

When you're working with the Azure CLI, locations are one of the most commonly used parts of commands you have to write. Some of them are really easy to remember, like `eastus`. But others may be a little bit harder to get right the first time, like `australiacentral2`.

One of the really great things about the Azure CLI is that you can dynamically figure out the location name for the region that you're looking for.

When you run `az account list-locations` you should get similar output (parts omitted for brevity):

```
DisplayName               Name                 RegionalDisplayName
------------------------  -------------------  -------------------------------------
East US                   eastus               (US) East US
East US 2                 eastus2              (US) East US 2
South Central US          southcentralus       (US) South Central US
West US 2                 westus2              (US) West US 2
Australia East            australiaeast        (Asia Pacific) Australia East
Southeast Asia            southeastasia        (Asia Pacific) Southeast Asia
North Europe              northeurope          (Europe) North Europe
UK South                  uksouth              (Europe) UK South
West Europe               westeurope           (Europe) West Europe
Central US                centralus            (US) Central US
Norway West               norwaywest           (Europe) Norway West
....
Switzerland West          switzerlandwest      (Europe) Switzerland West
UK West                   ukwest               (Europe) UK West
UAE Central               uaecentral           (Middle East) UAE Central
Brazil Southeast          brazilsoutheast      (South America) Brazil Southeast
```

Pipe that to `grep` and you can find out the `Name` of the location you want to use:

```
$ az account list-locations -o table | grep australia
Australia East            australiaeast        (Asia Pacific) Australia East
Australia                 australia            Australia
Australia Central         australiacentral     (Asia Pacific) Australia Central
Australia Central 2       australiacentral2    (Asia Pacific) Australia Central 2
Australia Southeast       australiasoutheast   (Asia Pacific) Australia Southeast
```

No more guessing the location name! And there are times when you may want to find out the [paired region](https://docs.microsoft.com/en-us/azure/best-practices-availability-paired-regions) for a particular location:

```
$ az account list-locations --query "[?name=='australiaeast'].{pairedRegion:metadata.pairedRegion[0].name}" -o tsv                                                                           
australiasoutheast
```

Now I know that `australiaeast` and `australiasoutheast` are paired regions.

Hopefully this blog post has shown a quick way to find out location names right from the command line!
