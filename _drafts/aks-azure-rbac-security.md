---
layout: post
title: Using Azure RBAC to Secure AKS Clusters
categories: [Blog]
tags: [azure,aks,kubernetes,security]
---

Role-based access control (RBAC) is the way that Azure secures access to its resources. With recent advancements in Azure Kubernetes Service (AKS), you are now able to use this same security mechanism to control access to your AKS clusters!

Being able to use this same mechanism means that your existing Azure RBAC knowledge and experience transfers to Kubernetes cluster security, not to mention the additional security benefits of Azure access control. This blog post will go over how to create and control access to AKS clusters with RBAC.

## Creating the cluster

Currently, the way to create an AKS cluster that is secured by RBAC, you need to specify `--enable-aad` and `--enable-azure-rbac` when creating the cluster:

```
$ az group create \
    --name rg1 \
    --location eastus

$ az aks create \
    --resource-group rg1 \
    --name aks1 \
    --enable-aad \
    --enable-azure-rbac
```

And that's it! Now you have an AKS cluster with RBAC!

## Built-in AKS RBAC roles

If you already have experience with Azure RBAC, you know that it is based on permissions that are given to **roles**. To give a security principal access you create a **role assignment**.

Oftentimes you can utilize built-in roles for Azure RBAC, and that's no different with AKS. Here is a current list of AKS RBAC roles:

```
$ az role definition list \
	--query "[?contains(roleName, 'Azure Kubernetes Service RBAC')].{roleName:roleName,description:description}"
```

```
[
  {
    "description": "Lets you manage all resources in the cluster.",
    "roleName": "Azure Kubernetes Service RBAC Cluster Admin"
  },
  {
    "description": "Lets you manage all resources under cluster/namespace, except update or delete resource quotas and namespaces.",
    "roleName": "Azure Kubernetes Service RBAC Admin"
  },
  {
    "description": "Allows read-only access to see most objects in a namespace. It does not allow viewing roles or role bindings. This role does not allow viewing Secrets, since reading the contents of Secrets enables access to ServiceAccount credentials in the namespace, which would allow API access as any ServiceAccount in the namespace (a form of privilege escalation). Applying this role at cluster scope will give access across all namespaces.",
    "roleName": "Azure Kubernetes Service RBAC Reader"
  },
  {
    "description": "Allows read/write access to most objects in a namespace.This role does not allow viewing or modifying roles or role bindings. However, this role allows accessing Secrets and running Pods as any ServiceAccount in the namespace, so it can be used to gain the API access levels of any ServiceAccount in the namespace. Applying this role at cluster scope will give access across all namespaces.",
    "roleName": "Azure Kubernetes Service RBAC Writer"
  }
]
```

To see the specific permissions in a role, you can do the following:

```
$ az role definition list --role-name "Azure Kubernetes Service RBAC Cluster Admin"
[
    ...
    "permissions": [
      {
        "actions": [
          "Microsoft.Authorization/*/read",
          "Microsoft.Insights/alertRules/*",
          "Microsoft.Resources/deployments/write",
          "Microsoft.Resources/subscriptions/operationresults/read",
          "Microsoft.Resources/subscriptions/read",
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.Support/*",
          "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action"
        ],
        "dataActions": [
          "Microsoft.ContainerService/managedClusters/*"
        ],
        "notActions": [],
        "notDataActions": []
      }
    ],
    "roleName": "Azure Kubernetes Service RBAC Cluster Admin",
    "roleType": "BuiltInRole",
    "type": "Microsoft.Authorization/roleDefinitions"
  }
]
```

## Designating cluster admins

To designate a user as a cluster admin, assign the **Azure Kubernetes Service RBAC Cluster Admin** role:

```
$ az role assignment create \
    --assignee "clusteradmin1@trstringer.com" \
    --role "Azure Kubernetes Service RBAC Cluster Admin" \
    --scope $(az aks show \
        --resource-group rg1 \
        --name aks1 \
        --query id -o tsv)
```

This gives the user cluster admin privileges on the scope of a specific AKS cluster.

## User cluster access

Not every user of the AKS cluster should be a cluster admin though. It's a typical use-case to grant a user just the ability to work inside a specific namespace. Remember to adhere to the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)!

### User credentials

To connect to your Kubernetes cluster from your local machine with `kubectl`, you need to retrieve your credentials:

```
$ az aks get-credentials \
    --resource-group rg1 \
    --name aks1 \
    --overwrite-existing
```

For a user with no RBAC permissions, you'll get the following error:

> The client 'user1@trstringer.com' with object id '...' does not have authorization to perform action 'Microsoft.ContainerService/managedClusters/listClusterUserCredential/action' over scope '/subscriptions/.../resourceGroups/rg1/providers/Microsoft.ContainerService/managedClusters/aks1' or the scope is invalid. If access was recently granted, please refresh your credentials.

To give a user the ability to get credentials to this AKS cluster, you need to grant the principal **Azure Kubernetes Service Cluster User Role** permissions:

```
$ az role assignment create \
    --assignee "user1@trstringer.com" \
    --role "Azure Kubernetes Service Cluster User Role" \
    --scope $(az aks show \
        --resource-group rg1 \
        --name aks1 \
        --query id -o tsv)
```

### Cluster access

Now the user should be able to successfully run `az aks get-credentials`. But, by default, if they try to do anything (such as listing pods), they would get an error:

```
$ kubectl get pods
```

> Error from server (Forbidden): pods is forbidden: User "user1@trstringer.com" cannot list resource "pods" in API group "" in the namespace "default": User does not have access to the resource in Azure. Update role assignment to allow access.

This user effectively has no permissions in the AKS cluster. If you want to give the user the ability to read *everything* in the AKS cluster, you can grant **Azure Kubernetes Service RBAC Reader** for the scope of the whole cluster:

```
$ az role assignment create \
    --assignee "user1@trstringer.com" \
    --role "Azure Kubernetes Service RBAC Reader" \
    --scope "$(az aks show \
        --resource-group rg1 \
        --name aks1 --query id -o tsv)"
```

Now this user will be able to successfully run `kubectl get pods`.

### Namespace access

Users typically need write access in one or more namespaces (for instance, a dev team that needs to create Kubernetes resources in the cluster). If a user tries to create (i.e. "write") a deployment, for example, in that namespace:

```
$ kubectl create deployment nginx --image=nginx -n appnamespace
```

They would get the following error:

> error: failed to create deployment: deployments.apps is forbidden: User "user1@trstringer.com" cannot create resource "deployments" in API group "apps" in the namespace "appnamespace": User does not have access to the resource in Azure. Update role assignment to allow access.

To grant this user write access in *only* that namespace, grant **Azure Kubernetes Service RBAC Writer** permissions at the scope of only the namespace:

```
$ az role assignment create \
    --assignee "user1@trstringer.com" \
    --role "Azure Kubernetes Service RBAC Writer" \
    --scope "$(az aks show \
        --resource-group rg1 \
        --name aks1 \
        --query id -o tsv)/namespaces/appnamespace"
```

Note that the `--scope` is in the formation of **AKS_ID/namespaces/NAMESPACE**.

Now this user will be able to successfully create that deployment in the `appnamespace` namespace, but in no other namespace!

## Summary

AKS is a great service allowing users to run managed Kubernetes clusters. With the security flow and familiarity of RBAC for access to the clusters, it makes it an even easier experience to work with!
