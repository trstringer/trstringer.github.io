---
layout: post
title: How to Learn Azure
categories: [Blog]
tags: [azure]
---

Azure is a massive cloud computing platform. Even Azure "experts" don't have the capacity to know all of the services, features, and solutions very deeply. But if you are new to Azure (or cloud computing).

But before you become an expert, you need to start learning. And with something so large, how do you learn? I like to equate the cloud with cars. I used to really enjoy working on cars. As a whole system, a car is a very complex machine. The amount of moving parts alone is enough to turn any learner away. But if you take the complex machine and break it up into smaller parts, you'll find that the complexity gets a more simplified. After all, (mostly) complex things are just a large number of simple ones.

I want this blog post to act as a guide. It'll show the key functions of a cloud and then dive into a few exercises you can do to learn about these things. This is absolutely meant to touch upon Azure functionality at the 100 level. To climb through to the level 400 capabilities, it'll take a lot more time and deeper learning. But you need to start somewhere...

## Compute

Compute is the backbone of most Azure services. This is the world that is usually most familiar to users. You're usually dealing with virtual machines (VMs). Before you learn about and discover higher level cloud abstractions, it is absolutely essential to first understand basic compute.

### Virtual machines

**Create a web server**

*Why?* A web server is a common requirement for a VM. This exercise will show how to create a VM and gain access to it, as well as setting up some basic software.

1. Create an Ubuntu Linux VM.
1. Successfully SSH into the VM.
1. Install nginx on the VM.
1. Configure public access to the VM, but only through ports 80 and 443.

The end of this exercise is to be able to publicly view the default nginx website from the internet.

**(Bonus) Setup HTTPS**

*Why?* Public key cryptography is the backbone of secure network communication. Learning the process of requesting a certificate and installing it on your web server can show how to leverage modern security practices.

1. Generate a private and public key pair.
1. Create a certificate signing request and send to Let's Encrypt.
1. Take the resulting certifcate from Let's Encrypt and enable SSL on your website.

The end of this exercise is to be able to successfully view the default nginx website through HTTPS. And extra bonus is to disable non-HTTPS traffic (and access) to this website.

**(Bonus) Setup custom DNS**

*Why?* DNS is a major component of network connectivity, being able to lookup an IP address given a hostname. After all, you're not typing IP addresses in your web browser!

1. Register a new domain name with a domain registrar.
1. Create an Azure DNS zone for your website and new domain.
1. Configure the necessary record sets.
1. Configure the DNS servers to use Azure DNS servers in your domain registrar.

The end of this exercise is to be able to use your custom domain name to browser the default nginx website from the internet.

### Containers and Kubernetes

## Storage and data

## Security

### RBAC

**Create a new role**

**Grant a user the ability to do something**

### Key Vault

**Store a secret in Azure Key Vault**

## Identity

### Azure Active Directory

**Create a new user in Azure AD**

**Create and work with a managed identity for a VM**

*Why?* Managed identities are a really easy and secure way to have your Azure compute resources accessing other Azure resources that use Azure AD for identity (e.g. Azure SQL databases, Azure storage, Key Vault, etc.).

1. Create a managed identity.
1. Give this identity the ability to list all resource groups in the subscription.
1. Create an Ubuntu VM that uses this managed identity.
1. Install the Azure CLI on the new VM.
1. Login with the Azure CLI (using the identity).
1. List all resource groups in the subscription.
