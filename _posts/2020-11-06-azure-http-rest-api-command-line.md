---
layout: post
title: Make HTTP Requests to the Azure REST API from the Command Line
categories: [Blog]
tags: [azure, devops]
---

I live in the terminal, and I will do everything I can to avoid the GUI and my computer mouse. This applies to everything, including my interactions with Azure.

For the msot part, the Azure CLI is the 99% solution for that. But every once in awhile I'll run into something I want to do that there is no command coverage from the Azure CLI.

So what are my options? Use the portal? Not if this is something that either I'll be doing again, need to automate it, or want it documented (which covers basically all of my scenarios).

Then what's the solution? **Make an HTTP request directly to the Azure REST API!** That might sound scary, but it is not. *It's easier than you think!*

# The short version

You can make an HTTP request to the [Azure REST API](https://docs.microsoft.com/en-us/rest/api/azure/) directly with the Azure CLI:

An example of this can be found below to show how to [list all resource groups](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups/list):

```
$ SUBSCRIPTION_ID=$(az account show --query id -o tsv)
$ az rest \
    --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourcegroups?api-version=2020-06-01 |
    jq ".value | .[] | .name" -r
```

This will give you a list of all resource group names. I piped the output of `az rest` to `jq` so that I could extract the desired data out of the JSON document.

`az rest` defaults to an `HTTP GET`, but if you need to use a different verb then you can explicitly specify this with the `--method` verb.

*Note: I put the subscription ID retrieval on a separate line for readability, but in practice I embed that command directly in my `az rest` call URL string.*

# The long version

## Using curl

As a Linux user, `curl` is a utility that I've used for a long time. And you can absolutely use it to make this HTTP request as well (this is what I used to do before I learned about `az rest`!).

A common use-case for this even now is if you are in an environment where you can't have the Azure CLI installed.

To curl the Azure REST API getting the same information as above (resource group list), you can do the following:

```
$ curl -sL \
    -H "authorization: bearer $(az account get-access-token --query accessToken -o tsv)" \
    -H "contenttype: application/json" \
    "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourcegroups?api-version=2020-06-01" |
    jq ".value | .[] | .name" -r
```

To authenticate with the API, we have to pass an access token. The easy way to do that is by embedding a call to `az account get-access-token`.

## Using the Azure CLI

At some point, the Azure CLI introduced a helper command to handle the headers for users: `az rest`.

Using the Azure CLI for HTTP requests to the REST API make it just a bit simpler to get the data. Reference the [above section](#the-short-version) on the specifics.

## REST API discovery

One last point I want to make is how I discover URLs in the REST API for those few times I need to invoke it directly. The easiest way is to just go to the [official documentation for the REST API](https://docs.microsoft.com/en-us/rest/api/azure/). There you can navigate and drill-down in the menu on the left to get to the service and functionality that you need.

Another tool is the [REST API browser](https://docs.microsoft.com/en-us/rest/api/?view=Azure), which allows you to have better searching by service, instead of by the provider (which could be less obvious).

Once you drill into the service, you can see all of the REST operations you can perform to accomplish what you need.

# Summary

The Azure REST API can be a daunting thing to work with directly, but through some help from the Azure CLI and searching through the documentation it can be a very approachable solution for those times when you need it in code!
