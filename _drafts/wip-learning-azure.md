---
layout: post
title: How to Learn Azure
categories: [Blog]
tags: [azure]
---

Azure is a massive cloud computing platform. Even Azure "experts" don't have the capacity to know all of the services, features, and solutions very deeply. But if you are new to Azure (or cloud computing).

But before you become an expert, you need to start learning. And with something so large, how do you learn? I like to equate the cloud with cars. I used to really enjoy working on cars. As a whole system, a car is a very complex machine. The amount of moving parts alone is enough to turn any learner away. But if you take the complex machine and break it up into smaller parts, you'll find that the complexity gets a more simplified. After all, (mostly) complex things are just a large number of simple ones.

I want this blog post to act as a guide. It'll show the key functions of a cloud and then dive into a few exercises you can do to learn about these things. This is absolutely meant to touch upon Azure functionality at the 100 level. To climb through to the level 400 capabilities, it'll take a lot more time and deeper learning. But you need to start somewhere...

## 1. Compute

Compute is the backbone of most Azure services. This is the world that is usually most familiar to users. You're usually dealing with virtual machines (VMs). Before you learn about and discover higher level cloud abstractions, it is absolutely essential to first understand basic compute.

### 1a. Virtual machines

**Create a web server**

*Why?* A web server is a common requirement for a VM. This exercise will show how to create a VM and gain access to it, as well as setting up some basic software.

1. Create an Ubuntu Linux VM.
1. Successfully SSH into the VM.
1. Install nginx on the VM.
1. Configure public access to the VM, but only through ports 80 and 443.

*Completion: publicly view the default nginx website from the internet.*

**(Bonus) Setup HTTPS**

*Why?* Public key cryptography is the backbone of secure network communication. Learning the process of requesting a certificate and installing it on your web server can show how to leverage modern security practices.

1. Generate a private and public key pair.
1. Create a certificate signing request and send to Let's Encrypt.
1. Take the resulting certifcate from Let's Encrypt and enable SSL on your website.

*Completion: view the default nginx website through HTTPS. And extra bonus is to disable non-HTTPS traffic (and access) to this website.*

**(Bonus) Setup custom DNS**

*Why?* DNS is a major component of network connectivity, being able to lookup an IP address given a hostname. After all, you're not typing IP addresses in your web browser!

1. Register a new domain name with a domain registrar.
1. Create an Azure DNS zone for your website and new domain.
1. Configure the necessary record sets.
1. Configure the DNS servers to use Azure DNS servers in your domain registrar.

*Completion: use your custom domain name to browser the default nginx website from the internet.*

### 1b. Containers and Kubernetes

**Locally build a container image**

*Why?* Containized workloads have a basic building block of containers and container images. Usually they are the result of a CI/CD pipeline but when developing, testing, and learning you typically would build the container image locally.

1. Create a hello world application in your desired language/platform.
1. Create a Dockerfile.
1. Successfully build the image.

*Completion: be able to run the container locally.*

**Work with a container registry**

*Why?* Container registries store container images so that other users and systems (e.g. Kubernetes) can utilize them.

1. Create an Azure Container Registry.
1. Push your container image to the container registry.

*Completion: successfully view the container image in ACR.*

**Azure Kubernetes Service**

*Why?* Azure Kubernetes Service, or AKS, is the managed Kubernetes offering in Azure. It provides a Kubernetes cluster for you to run your workloads.

1. Create an AKS cluster.
1. Attach your container registry to the cluster.
1. Create a pod that uses your container image from your container registry.

*Completion: view the successful pod running in your AKS cluster.*

### 1c. Web apps

**Create an Azure Web App**

*Why?* Running web workloads in Azure can be less to manage and maintain than running on a VM.

1. In your [supported language and platform of choice](https://docs.microsoft.com/en-us/azure/app-service/overview#why-use-app-service), create a web app.
1. Deploy this web app to Azure.

### 1d. Serverless

## 2. Storage and data

### 2a. Blob storage

### 2b. Files

### 2c. Azure Databases

### 2d. Cosmos

### 2e. Redis

## 3. Security and identity

### 3a. Azure Active Directory

**Create a new user in Azure AD**

1. Create a new user in Azure AD.
1. Grant the user access to read a single resource group (RBAC).

*Completion: login with the new user and verify access to the resource group.*

**Create and use a managed identity for a VM**

*Why?* Managed identities are a really easy and secure way to have your Azure compute resources accessing other Azure resources that use Azure AD for identity (e.g. Azure SQL databases, Azure storage, Key Vault, etc.).

1. Create a managed identity.
1. Give this identity the ability to list all resource groups in the subscription.
1. Create an Ubuntu VM that uses this managed identity.
1. Install the Azure CLI on the new VM.
1. Login with the Azure CLI (using the identity).
1. List all resource groups in the subscription.

### 3b. RBAC

**Create a new role**

1. Create a new role with permissions to list Virtual Machines.
1. Assign this role to a user by creating a role definition.

*Completion: verify that the user can now accomplish the actions in the role definition.*

**Grant a user the ability to do something**

### 3c. Key Vault

**Store a secret in Azure Key Vault**
