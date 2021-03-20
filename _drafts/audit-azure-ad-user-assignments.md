---
layout: post
title: Audit Azure AD User Role Assignments
categories: [Blog]
tags: [azure,security]
---

A typical security guideline is that you should not be granting permissions *directly* to users. Instead you should prefer granting the permissions on a group. Then to give users permissions it should be through their group membership. This is better and easier because in the event a user no longer needs access (usually with a change in position, or a dev team that shifts focus), you don't have to unassign permissions to that user (and possibly a whole team). You just need to remove them from the group that they no longer need to be a part of.

But... like many things in IT, it doesn't always happen that way. What if you want to audit/find all RBAC role assignments to individual users? The following Azure CLI command will show you this information:

```
$ az role assignment list \
    --all \
    --query "[?principalType=='User'].{principalName:principalName,roleDefinitionName:roleDefinitionName,scope:scope}"
```

My output looks like this:

```
[
  {
    "principalName": "thomas@trstringer.com",
    "roleDefinitionName": "Azure Kubernetes Service RBAC Cluster Admin",
    "scope": "/subscriptions/..."
  },
  ...
]
```

What you do with this information is completely up to you. Perhaps you will determine that a particular user role assignment is necessary. Or maybe you will want to create a group and create role assignments through the group.

Hopefully this quick post shows you how to quickly and effectively list out some very important security information!
