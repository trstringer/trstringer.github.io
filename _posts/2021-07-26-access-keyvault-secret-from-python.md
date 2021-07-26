---
layout: post
title: Access an Azure Key Vault Secret from Python
categories: [Blog]
tags: [azure,python,security]
---

Digital security is very important. It has long been understood that we should not be storing secret data in code or any other insecure storage. This data should be stored in a secure key management system and retrieved only when needed, and not persisted. This solution in Azure is [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general/overview).

This requirement is no different for our Python scripts or applications. But how can we access Azure Key Vault secrets from our Python code? This blog post will show you how to do that!

## Key Vault setup

Before we can get the secrets from Azure Key Vault, we need to first set it up. First we will create the Key Vault:

```
$ az keyvault create \
    --resource-group rg1 \
    --name keyvault1 \
    --enable-rbac-authorization
```

By specifying `--enable-rbac-authorization` we are using [Azure RBAC](https://docs.microsoft.com/en-us/azure/role-based-access-control/overview) to control access to this Key Vault.

Now let's create a test secret:

```
$ az keyvault secret set \
    --vault-name keyvault1 \
    --name secret1 \
    --value 'MyTestSecret'
```

## Installing Python dependencies

Before we can access this secret from our Python code, we have to install a couple of dependencies. I like to keep all of my dependencies contained in a virtual environment:

```
$ python3 -m venv venv
$ . venv/bin/activate
```

Then I need to install two different dependencies:

- `azure-identity` for the auth component
- `azure-keyvault-secrets` for Key Vault secret access

```
$ pip install \
    azure-identity \
    azure-keyvault-secrets
```

## Access a Key Vault secret from Python

Now that we have everything setup, let's see the code that can access this Key Vault secret.

First we need to create a `DefaultAzureCredential`. I talked about this [in a blog post explaining how to authenticate to Azure from Python](https://trstringer.com/authenticate-python-to-azure/), but in short this is a great helper class that tries multiple different ways to authenticate that translate from a development machine that is logged into the Azure CLI to using a managed identity which is a great production-ready way to access Azure resources.

```python
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
```

Now we need to create the `SecretClient`, which will allow us to access the secrets in the Key Vault. But before we do that, we need to get the Key Vault URI (I used the Azure CLI):

```
$ az keyvault show \
    --name keyvault1 \
    --query "properties.vaultUri" -o tsv
```

This should be in the format of `https://<key_vault_name>.vault.azure.net/`.

Taking that Key Vault URI, we can create the client:

```python
from azure.keyvault.secrets import SecretClient

client = SecretClient(
    vault_url="https://KEY_VAULT_NAME.vault.azure.net/",
    credential=credential
)
```

Then you can access the secret with a call to `get_secret`:

```python
secret = client.get_secret("secret1")
```

And the value of the secret can get accessed by `value`:

```python
print(f"Secret value is {secret.value}")
```

The full code for this example is below:

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://KEY_VAULT_NAME.vault.azure.net/",
    credential=credential
)
secret = client.get_secret("secret1")
print(f"Secret value is {secret.value}")
```

And the expected output is `Secret value is MyTestSecret`.

## Summary

Hopefully this blog post has shown how easy it is to securely store your secrets in Azure Key Vault and access them from your Python code!
