---
layout: post
title: Sherlock - a sandbox environment provisioning tool for your integration testing pipeline in Azure
categories: [Blog]
tags: [azure, devops]
---

One of my primary focuses these days is developing Azure support for Red Hat's Ansible (if you are unfamiliar with Ansible, check it out. It is a great tool for DevOps and configuration management). One of the missing parts was integration testing for Azure modules. Not only with new module development, but also regression testing to fill out a proper continuous integration flow.

I wanted to have a reproducible way to create a sandbox environment in an Azure subscription. In Azure, this would translate to a resource group and a service principal that only has rights within the resource group. For a user or automation software to only have rights to a fresh new resource group (or two) it should result in a fairly secure environment.

Enter [Sherlock](https://github.com/trstringer/sherlock)...

## What the user sees

The end user will make a web API request, specifying the following query params:

* **rgcount** - the amount of resource groups needed (this defaults to 1)
* **region** - the region to create the resource group(s) in (defaults to eastus)
* **duration** - the amount of time, in minutes, that the resource group(s) and Azure AD service principal should live for (defaults to 30 minutes)

When the process completes, a response with the following is returned:

* **resourceGroupNames** - an array of the names of the resource group(s) that were created
* **clientId** - the ID of the service principal that was created and that you should use to connect to the subscription and new resource group(s)
* **clientSecret** - the strong auto-generated password/key for the service principal that you would use to authenticate against the Azure subscription
* **subscriptionId** - the Azure subscription ID
* **tenantId** - the Azure Active Directory tenant ID

## How this works

Sherlock is nothing more than an Azure Function App that you would setup in your Azure subscription. The Azure Function App consists of two different Functions:

* **sandbox-provisioning** - this is the web API that handles the user requests and creates the resource group(s) and AAD artifacts
* **cleanup** - this is the cron job that routinely checks the expiration date/time (this is stored as a tag on the generated resource groups) and if a resource group is passed expiration, it removes it. It also removes the AAD application that corresponds to the deleted resource groups (in essence leaving no remains of the environment)

## Setup and configuration

*Please see the GitHub repository's README for detailed instructions.*

## How do I know if I need Sherlock?

Here are a few good questions to ask yourself if you are unsure if Sherlock is right for you:

1. Do you have an active CI/CD pipeline for your software and is your target Microsoft Azure?
1. Do you currently practice integration testing, or do you have the desire to implement integration tests?
1. Would you like your integration tests to run directly in an Azure subscription for the utmost accurate results?
1. Are you after an automated solution to manage the secure sandboxes, from creation to deletion?

If those answers are "yes", take a look at Sherlock. If you have any questions or concerns, please don't hesitate to reach out.

Enjoy!
