---
layout: post
title: Query Azure Resources by Tags with the Azure CLI
categories: [Blog]
tags: [azure]
---

[Azure resource tags](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) are one of the really great features that I don't think gets talked about as much as it should. Tags are key-value pairs that you can put on your Azure resources.

Although tags themselves can be "written" many times, it is more common to "read" them. After all, that's what they're there for. So while it is easy and straightforward to write tags on resources, querying them can be a little more challenging.

Let's go through a few examples on how to query the tags, but first a few resource groups to experiment with:

```
$ az group create \
    --name tagrg1 \
    --location eastus \
    --tags Team=Engineering Lifecycle=Production Event=Rollout

$ az group create \
    --name tagrg2 \
    --location eastus \
    --tags Team=Marketing Lifecycle=Production Event=Stable-release

$ az group create \
    --name tagrg3 \
    --location eastus \
    --tags Team=Engineering Lifecycle=Testing

$ az group create \
    --name tagrg4 \
    --location eastus \
    --tags Team=Engineering Lifecycle=Production Event=Stable
```

Here's an easier way to visualize these tags:

| Resource group name | Team | Lifecycle | Event |
| ------------------- | ---- | --------- | ----- |
| tagrg1 | Engineering | Production | Rollout |
| tagrg2 | Marketing | Production | Stable-release |
| tagrg3 | Engineering | Testing | |
| tagrg4 | Engineering | Production | Stable |

This is a pretty good (sample) tagging stategy. But how do we query resource groups with different requirements? Let's see a handful of ways to retrieve the desired resource groups by tags.

*Note: I know that with `az group list` you can specify a `--tag` to search by, but in my experience it is very limited for most scenarios, so I tend to ignore this parameter.*

## Search tag value

*Scenario*: Get all resource groups that have `Team` set to `Engineering`.

```
$ az group list \
    --query "[?tags.Team == 'Engineering']" -o table
```

```
Name            Location
--------------  ----------
tagrg1          eastus
tagrg3          eastus
tagrg4          eastus
```

## Search missing tag values

*Scenario*: Get all resource groups that have `Team` *not* set to `Engineering`.

```
$ az group list \
    --query "[?tags.Team && tags.Team != 'Engineering']" -o table
```

```
Name            Location
--------------  ----------
tagrg2          eastus
```

This one is a little trickier. If we just had a query of `"[?tags.Team!='Engineering']"` that would return resources that don't even include the `Team` tag, which is most likely not our desired output.

## Search missing tag keys

*Scenario*: Get all resource groups that don't have the `Event` tag set.

```
$ az group list \
    --query "[?tags.Event == null]" -o table
```

```
Name            Location
--------------  ----------
tagrg3          eastus
```

## Search multiple tag values

*Scenario*: Get all resource groups with `Team` set to `Engineering` and `Lifecycle` set to `Production`.

```
$ az group list \
    --query  "[?tags.Team == 'Engineering' && tags.Lifecycle == 'Production']" -o table
```

```
Name            Location
--------------  ----------
tagrg1          eastus
tagrg4          eastus
```

## Search tag value containing string

*Scenario*: Get all resource groups that have the word `"Stable"` in the `Event`.

```
$ az group list \
    --query "[?tags.Event != null && contains(tags.Event, 'Stable')]" -o table
```

```
Name            Location
--------------  ----------
tagrg2          eastus
tagrg4          eastus
```

## Summary

Azure resource tags are really great ways to contain key-value data. Some examples are: Business unit ownership, lifecycle tag, resource notes, etc. Being able to quickly and effectively query the tags is a good skill to have when searching for resources!
