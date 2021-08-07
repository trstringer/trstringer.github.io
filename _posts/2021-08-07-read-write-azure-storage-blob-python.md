---
layout: post
title: Reading and Writing an Azure Storage Blob from Python
categories: [Blog]
tags: [azure,linux,python]
---

Working with Azure Blob Storage is a common operation within a Python script or application. This blog post will show how to read and write an Azure Storage Blob.

## Setup

Before you begin, you need to create the Azure Storage account:

```
$ az group create \
    --name rg1 \
    --location eastus
$ az storage account create \
    --resource-group rg1 \
    --name storage1
```

Now we need to install our Python dependencies (I use virtual environments to contain dependencies):

```
$ pip install azure-identity azure-storage-blob
```

Retrieve your blob URL with (this will be used later):

```
$ az storage account show \
    --resource-group rg1 \
    --name storage1 \
    --query "primaryEndpoints.blob" -o tsv
```

## Connecting

The first step is to get your credentials (through `DefaultAzureCredential`) and then create the `BlobServiceClient` from the blob URL retrieved above.

```python
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobClient, BlobServiceClient

account_url = "https://storage1.blob.core.windows.net/"

creds = DefaultAzureCredential()
service_client = BlobServiceClient(
    account_url=account_url,
    credential=creds
)
```

## Creating the container

When working with blobs, you need to deal with containers. It might already exist, in which case you can start working with it. But in the event that you need to create the container, you can do something similar:

```python
container_name="mycontainer"
service_client.create_container(name=container_name)
```

## Blob client

To write to (and read from) the a blob, we need to create the blob client:

```
blob_name = "testblob1"
blob_url = f"{account_url}/{container_name}/{blob_name}"

blob_client = BlobClient.from_blob_url(
    blob_url=blob_url,
    credential=creds
)
```

## Write to the blob

Now we are ready to write to the blob. In my case, I'm taking the contents of a local file to "upload" it to the blob:

```python
with open("/tmp/azure-blob.txt", "rb") as blob_file:
    blob_client.upload_blob(data=blob_file)
```

## Reading the blob

To read, or "download", the blob you can do the following:

```python
blob_download = blob_client.download_blob()
blob_content = blob_download.readall().decode("utf-8")
print(f"Your content is: '{blob_content}'")
```

## Summary

Hopefully this quick blog post has showed you how to read from and write to an Azure Storage blob!
