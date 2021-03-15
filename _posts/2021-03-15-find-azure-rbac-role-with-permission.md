---
layout: post
title: Find which Azure RBAC Roles Contain a Permission
categories: [Blog]
tags: [azure,python]
---

Azure role-based access control (RBAC) is the access management that Azure uses for resources. When giving a principal access to certain resources, you need to either use an existing role or create a new role, and then assign that role to the principal.

Oftentimes you will need to figure out which Azure RBAC role contains certain permissions. You could search and parse the output of `az role definition list`, but that could take a long time (and just generally not be very fun).

Let's say you want to assign a role to a user that includes the permission **Microsoft.Insights/alertRules/read** permission. Before you create a new role, you might want to see what existing roles already have that permission.

Here's a Python script that I wrote to search for a particular permission in all RBAC roles:

```python
import sys
from azure.identity import DefaultAzureCredential
from azure.mgmt.authorization import AuthorizationManagementClient

if len(sys.argv) < 2:
    print("You need to supply the permission to search for")
    sys.exit(1)

credential = DefaultAzureCredential()
client = AuthorizationManagementClient(
    credential=credential,
    subscription_id="YOUR_SUBSCRIPTION_ID"
)

desired_action = sys.argv[1]
desired_action_lower = desired_action.lower()
desired_action_wildcard = "/".join(desired_action_lower.split("/")[:-1] + ["*"])

role_definitions = list(client.role_definitions.list(scope=""))
for role_def in client.role_definitions.list(scope=""):
    for permission in role_def.permissions:
        for action in permission.actions:
            if action.lower() == desired_action_lower or action.lower() == desired_action_wildcard:
                print(f"Role '{role_def.role_name}' contains {action}")
```

The script has the following dependencies:

- `azure-identity`
- `azure-mgmt-authorization`

Now you can run the script: `$ python search_rbac_roles.py "Microsoft.Insights/alertRules/read"`:

```
Role 'API Management Service Contributor' contains Microsoft.Insights/alertRules/*
Role 'API Management Service Operator Role' contains Microsoft.Insights/alertRules/*
Role 'API Management Service Reader Role' contains Microsoft.Insights/alertRules/*
Role 'Application Insights Component Contributor' contains Microsoft.Insights/alertRules/*
Role 'Application Insights Snapshot Debugger' contains Microsoft.Insights/alertRules/*
Role 'Automation Job Operator' contains Microsoft.Insights/alertRules/*
Role 'Automation Runbook Operator' contains Microsoft.Insights/alertRules/*
... some output removed for brevity ...
Role 'Desktop Virtualization Workspace Reader' contains Microsoft.Insights/alertRules/read
Role 'Collaborative Runtime Operator' contains Microsoft.Insights/alertRules/*
Role 'Quota Request Operator Role' contains Microsoft.Insights/alertRules/*
Role 'EventGrid Contributor' contains Microsoft.Insights/alertRules/*
```

Now you have the list of roles that include this permission. I wrote the script so that it also looks at the wildcard "*" permission too, which would include the permission you are interested.

Searching through Azure RBAC roles (there are a *lot* of them) can be a long task, but with this quick Python script you can quickly locate which roles have a permission!
