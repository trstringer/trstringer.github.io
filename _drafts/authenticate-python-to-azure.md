---
layout: post
title: Authenticate to Azure from Python
categories: [Blog]
tags: [azure,python]
---

Python is one of the most popular programming languages today, and for good reason: It allows you to quickly develop powerful software in a very expressive and delightful way. Python is one of my favorites!

Python is *also* a great tool for writing applications or scripts to interact with cloud resources. Azure provides great support for this through the [Azure SDK for Python](https://docs.microsoft.com/en-us/azure/developer/python/azure-sdk-overview). As powerful and capable as this is, one of the first things you need to do in your Python code to interact with Azure and your Azure resources is to authenticate.

One of the really great and easy things that was introduced in the Azure Python SDK is the **[DefaultAzureCredential](https://azuresdkdocs.blob.core.windows.net/$web/python/azure-identity/1.4.0/azure.identity.html#azure.identity.DefaultAzureCredential)** helper class. It is a great single solution for all of your authentication requirements because it tries five different sources of authentication. They are, in order:

1. Environment variables (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, and [more](https://azuresdkdocs.blob.core.windows.net/$web/python/azure-identity/1.4.0/azure.identity.html#azure.identity.EnvironmentCredential))
1. Managed identity - if you are running your Python code in an Azure VM, web app, AKS cluster, or any other compute that supports managed identities, it will choose this for authentication
1. [Visual Studio Code credentials](https://azuresdkdocs.blob.core.windows.net/$web/python/azure-identity/1.4.0/azure.identity.html#azure.identity.VisualStudioCodeCredential)
1. Azure CLI - if you are logged into the machine with the Azure CLI it can use those credentials
1. Interactive login through the browser (just like when you do `az login`)

This is really great! The **managed identity** support is perfect for the situation when your code is running in an Azure VM (which we'll see below). The Azure CLI authentication is great for running your code on your local machine. The great thing? *The code is the same!*

Let's see an example:

```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource.resources import ResourceManagementClient

credential = DefaultAzureCredential()

client = ResourceManagementClient(
    credential=credential,
    subscription_id="YOUR_SUBSCRIPTION_ID"
)

for resource_group in client.resource_groups.list():
    print(f"Resource group: {resource_group.name}")

print(f"Successful credential: {credential._successful_credential.__class__.__name__}")
```

All this code does is log onto your Azure subscription and lists out the resource group names. To run this code, you need the following Python libraries:

- `azure-identity` (includes the `DefaultAzureCredential` class)
- `azure-mgmt-resource` (includes the `ResourceManagementClient`, which is used for the sample code)

Running this code on my **local machine that is logged into the Azure CLI**, I get the following output:

```
EnvironmentCredential.get_token failed: EnvironmentCredential authentication unavailable. Environment variables are not fully configured.
ManagedIdentityCredential.get_token failed: ManagedIdentityCredential authentication unavailable, no managed identity endpoint found.
Runtime dependency of PyGObject is missing.
Depends on your Linux distro, you could install it system-wide by something like:
    sudo apt install python3-gi python3-gi-cairo gir1.2-secret-1
If necessary, please refer to PyGObject's doc:
https://pygobject.readthedocs.io/en/latest/getting_started.html
Traceback (most recent call last):
  File "/home/trstringer/dev/azure-python/venv/lib/python3.9/site-packages/msal_extensions/libsecret.py", line 21, in <module>
    import gi  # https://github.com/AzureAD/microsoft-authentication-extensions-for-python/wiki/Encryption-on-Linux
ModuleNotFoundError: No module named 'gi'
SharedTokenCacheCredential.get_token failed: SharedTokenCacheCredential authentication unavailable. No accounts were found in the cache.
VisualStudioCodeCredential.get_token failed: Failed to get Azure user details from Visual Studio Code.
Resource group: NetworkWatcherRG
Resource group: DefaultResourceGroup-CUS
Resource group: trstringerdns1
Resource group: trstringerpy1
Successful credential: AzureCliCredential
```

If you read the output *before* "Resource group..." (which is my application code), you'll see that it goes through all possibilities until it finds one that works. It fails on `EnvironmentCredential`, `ManagedIdentityCredential`, `SharedTokenCacheCredential`, and `VisualStudioCodeCredential` before it succeeds on the `AzureCliCredential`, which we can see on the last line of output (this is retrieved from `credential._successful_credential`).

I then created an **Azure Linux VM with a managed identity**, and ran this exact same code:

```
EnvironmentCredential.get_token failed: EnvironmentCredential authentication unavailable. Environment variables are not fully configured.
Resource group: NetworkWatcherRG
Resource group: DefaultResourceGroup-CUS
Resource group: trstringerdns1
Resource group: trstringerpy1
Successful credential: ManagedIdentityCredential
```

You can see here that it goes through the same credential order. It fails on `EnvironmentCredential` (because those environment variables are not set), but then immediately succeeds with `ManagedIdentityCredential` because this Azure VM has a managed identity assigned to it.

*Note: Make sure that your managed identity has the correct RBAC permissions, otherwise you will the error: "azure.core.exceptions.HttpResponseError: (AuthorizationFailed) The client '...' with object id '...' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/read' over scope '/subscriptions/...' or the scope is invalid. If access was recently granted, please refresh your credentials."*

Hopefully this blog post has illustrated the simplicity, ease, and flexibility of using the **DefaultAzureCredential** to authenticate your Python code to your Azure subscription!
