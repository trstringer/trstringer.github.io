---
layout: post
title: Use Azure Blob Storage for Remote Terraform State
categories: [Blog]
tags: [azure, devops, terraform]
---

If you aren't yet familiar with Terraform, I highly recommend you check it out for some extremely amazing DevOps; specifically around Infrastructure as Code (IaC).

One of the things that Terraform does (and does really well) is "tracks" your infrastructure that you provision. It does this through the means of `state`. By default Terraform will store your state locally in a file called `terraform.tfstate`. If you are working by yourself... on a single computer... this works great. But oftentimes we are working in teams, or we want the flexibility to develop in multiple environments. This is where we won't want to use the default local state.

## A little terminology

Before we get much deeper here, let's go over some Terraform-specific verbiage. When we're dealing with remote storage, the where is called the "backend". Terraform supports a large array of backends, including Azure, GCS, S3, etcd and [many many more](https://www.terraform.io/docs/backends/types/index.html).

We'll be concentrating on setting up Azure Blob Storage for our backend to store the Terraform state.

## A basic Terraform configuration to play with

We need some actual Terraform IaC to work with as a sample to make sure everything is functioning correctly. I'm going to keep my single file main.tf super simple, and have it create a single resource group. Quick, easy... I don't need a complex infrastructure to show how to use remote state...

```
resource "azurerm_resource_group" "myrg" {
 name = "sample-rg"
 location = "eastus"
}
```

## Define the backend

This is where need to start telling Terraform exactly where our remote storage should live. I like to create a separate file called backend.tf and the definition is simple...

```
terraform {
 backend "azure" {}
}
```

We could have included the necessary configuration (storage account, container, resource group, and storage key) in the backend block, but I want to version-control this Terraform file so collaborators (or future me) know that the remote state is being stored. But in order for Terraform to know the specifics of Azure Blob Storage to store our state, we need to pass in that data during initialization.

## Initialization variables

As mentioned above, we don't want to specify sensitive information in the `backend.tf` file as we'll be commiting this to our git repository. The solution here is to create a separate file (make sure to add this to `.gitignore`!), I like to call it `beconf.tfvars`. This is just a "key = value" format file (if you've been working with Terraform the *.tfvars format should feel familiar)...

```
resource_group_name = "resource group name"
storage_account_name = "storage account name"
container_name = "container name"
key = "storage key"
```

Of course you need to specify the correct values here for your subscription and storage account.

*Note: Whereas you should definitely keep this beconf.tfvars file out of version control, I recommend you create a template for this by copying it to a file i.e. beconf.sample.tfvars and substitute your actual values for '...' or something similar. That way when somebody starts working with the repository they can back-track and create beconf.tfvars quickly.*

## Running initialization

We've set up all of the necessary files to tell Terraform to use remote state and store it in Azure Blob Storage. Now let's kick it off!

```
$ terraform init -backend-config=beconf.tfvars
```

By running terraform init we are using the -backend-config parameter to pass in our specific variables for our backend that are defined in beconf.tfvars and expected in backend.tf. We should've gotten a nice message...

> Successfully configured the backend "azure"! Terraform will automatically
> use this backend unless the backend configuration changes.
> 
> Terraform has been successfully initialized!

Now running through common workflows like `terraform plan` and `terraform apply` you'll notice that there is no longer a `terraform.tfstate` file being created/used locally. But there is now a `.terraform` directory, and inside that directory is a new `terraform.tfstate` file that doesn't include the state itself, but points to the backend configuration where the state is stored.

**Much like terraform.tfstate and beconf.tfvars, you should ensure that you are not committing .terraform/ to version control, as it contains sensitive information.**

## One last quick note...

You may be tempted to reuse a container for multiple Terraform configurations (read: projects), but from my experimentation this is not possible. Use/create a different container for different Terraform state. New project/infrastructure? Create a new container.

## Conclusion

There you have it! You have successfully configured and stored your Terraform state in Azure Blob Storage so that it is no longer local. This allows you to work across a team and multiple machines.

Enjoy!
