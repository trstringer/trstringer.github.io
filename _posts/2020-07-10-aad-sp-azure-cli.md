---
layout: post
title: Azure Active Directory Service Principals and Permissions from the Azure CLI
categories: [Blog]
tags: [azure]
---

A lot of us, especially in the non-Windows world, rely heavily on the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) to do our day-to-day jobs: As engineers, developers, administrators, etc. When dealing with Azure, you are destined to work with [Azure Active Directory](https://azure.microsoft.com/en-us/services/active-directory/) to provide identity services. One of the commonly used components of Azure Active Directory (AD) is [service principals](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals). Service principals allow you to control access to resources secured by Azure AD (most likely programmatically).

## Common mistake

When you create your service principals, you might do the following:

```
$ az ad sp create-for-rbac
```

When you run that you get the feedback you're looking for:

```
{
  "appId": "<app_id>",
  "displayName": "<display_name>",
  "name": "<name>",
  "password": "<password>",
  "tenant": "<tenant>"
}
```

Then you take your service principal and work with it, likely never thinking twice about it.

But what roles do your new service principal have?

```
$ az role assignment list --assignee <app_id>
[
  {
    "canDelegate": null,
    "id": "...",
    "name": "...",
    "principalId": "...",
    "principalName": "<service_principal_name>",
    "principalType": "ServicePrincipal",
    "roleDefinitionId": "...",
    "roleDefinitionName": "Contributor",
    "scope": "/subscriptions/<subscription_id>",
    "type": "..."
  }
]
```

I've kept the parts that I want us to focus on here. As you can see from above, this service principal has **Contributor** permissions **on the entire subscription**. The whole Azure subscription! If you're unfamiliar with Azure RBAC, the [Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) role can do everything in its scope (in this case, the subscription) except grant access to resources.

Contributor on the subscription is a a lot of permissions, and most likely doesn't conform to the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege).

This behavior is documented in the Azure CLI:

```
$ az ad sp create-for-rbac --help

Command
    az ad sp create-for-rbac : Create a service principal and configure its access to Azure
    resources.

Arguments
    --name -n          : A URI to use as the logic name. It doesn't need to exist. If not present,
                         CLI will generate one.
    --role             : Role of the service principal.  Default: Contributor.
    --scopes           : Space-separated list of scopes the service principal's role assignment
                         applies to. Defaults to the root of the current subscription. e.g.,
                         /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333,
                         /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup,
                         or /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGro
                         up/providers/Microsoft.Compute/virtualMachines/myVM.
    --sdk-auth         : Output result in compatible with Azure SDK auth file.  Allowed values:
                         false, true.
    --skip-assignment  : Skip creating the default assignment, which allows the service principal to
                         access resources under the current subscription. When specified, --scopes
                         will be ignored. You may use `az role assignment create` to create role
                         assignments for this service principal later.  Allowed values: false, true.

... rest of output omitted ...
```

The default for `--role` is `Contributor` and the default for `--scopes` is the current subscription. So in other words, by specifying nothing and leaving it up to the defaults that leaves us with Contributor on the subscription.

## The right way

So if this is the wrong way, then what's the right way? Limit the scope and the privileges of the service principal from the start. This can be done in a couple of ways. Either explicitly specify the `--role` and `--scopes` when you call `az ad sp create-for-rbac`, or specify `--skip-assignment` (and then assign roles afterwards if necessary).

Let's see what this looks like:

```
$ az ad sp create-for-rbac --skip-assignment
... service principal creation output ...

$ az role assignment list --assignee <new_app_id>
[]
```

By specifying `--skip-assignment` we have created a service principal without any roles (confirmed by the empty array of role assignments listed above).

## Summary

Be careful when creating Azure AD service principals with the Azure CLI. The safest way is to `--skip-assignment` and then explicitly create role assignments as needed.
