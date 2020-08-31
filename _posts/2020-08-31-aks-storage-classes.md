---
layout: post
title: AKS StorageClass Objects and Provisioners
categories: [Blog]
tags: [azure, kubernetes, aks]
---

Storage (typically) plays a large role in software systems. With Kubernetes that is, of course, no different. The way Kubernetes handles storage can be a little confusing, especially in cloud-provided scenarios. This post will explain some basics of storage in Kubernetes and also the options that are available in the Azure Kubernetes Service (AKS).

## How storage works in Kubernetes

There are a few layers of storage in Kubernetes. What you provide to the pods is a **PersistentVolumeClaim** (PVC). This PVC is a claim to a **PersistentVolume** (PV). A PV is created either manually or it can be created automatically through the use of a **StorageClass**.

There is a lot more complexity to how this works in Kubernetes, but it is beyond the scope of this blog post. If you're interested in learning more, take a look at the following resources:

- [Persistent Volumes (Kubernetes official docs)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes (Kubernetes official docs)](https://kubernetes.io/docs/concepts/storage/storage-classes/)

This post will be focusing on StorageClass objects. A StorageClass will either be created by the Kubernetes cluster user, or sometimes (like we'll see in this blog post) there are StorageClass objects that already ship with the cloud provider. Let's focus on what AKS provides users for storage.

## Provisioners available for Azure

The layer under a StorageClass that provides the storage is the **Provisioner**. There are two provisioners for Azure: [Azure File](https://kubernetes.io/docs/concepts/storage/storage-classes/#azure-file) and [Azure Disk](https://kubernetes.io/docs/concepts/storage/storage-classes/#azure-disk).

**Azure Disk** uses a either a managed or an unmanaged disk as the storage backing. You can specify the storage account type which will provide you with the required performance that you need for this storage.

**Azure File** is backed by an SMB share from a storage account (either standard with HDD or premium with SSD).

## Built-in StorageClass objects in AKS

One of the benefits of running Kubernetes in Azure with AKS is that it ships with out-of-the-box StorageClass objects.

```
 $ kubectl get storageclass
NAME                PROVISIONER                AGE
azurefile           kubernetes.io/azure-file   8m31s
azurefile-premium   kubernetes.io/azure-file   8m31s
default (default)   kubernetes.io/azure-disk   3m30s
managed-premium     kubernetes.io/azure-disk   3m30s
```

You can see here which are Azure Disk and which are Azure File by the `PROVISIONER` column. To see the specifics of these StorageClass objects you can run `kubectl get storageclass <sc_name> -o yaml`.

As of the writing of this post, here are the differences between the respective StorageClass objects in the same provisioniner.

### Azure Disk

`default` has a storage account type of **StandardSSD_LRS**. It is a **managed** disk.

`managed-premium` has a storage account type of **Premium_LRS** and is also a **managed** disk.

### Azure File

`azurefile` has a **Standard_LRS** storage account type.

`azurefile-premium` has a **Premium_LRS** storage account type.

## Create your own StorageClass

We have talked about the StorageClass objects that are provided from AKS, but that doesn't mean you are restricted to only using those. Like other resources in Kubernetes, you are free to define your own custom StorageClass (and are recommended in doing this, especially if no other StorageClass fits your software's needs).

*Note: Any changes made to the default StorageClass objects will be overwritten! If you need to slightly modify the behavior of a built-in StorageClass then a separate one should be created.*

## Choosing between different StorageClass objects

There are a couple of factors involved in determining which StorageClass you should be using for your Azure storage needs in your cluster. The primary one is if the storage needs to be accessed by a single pod or by multiple pods. If you require multiple pods to access the storage then you must use a StorageClass with the Azure File provisioner. But if you require only a single pod to access the storage then you can use an Azure Disk.

And of course your application performance requirements will dictate the underlying storage that you need to use. For more information on selecting the right storage, see [this official documentation (Best practices for storage and backups in Azure Kubernetes Service)](https://docs.microsoft.com/en-us/azure/aks/operator-best-practices-storage).

## Example

Here's a quick example of using Azure storage in an AKS cluster. My (fake) requirements are that I need multiple pods to be able to access the storage (`ReadWriteMany`), so that means I'm going to have to use a StorageClass with the Azure File provisioniner. I'll choose `azurefile`, as I don't need the performance of premium storage.

### PersistentVolumeClaim

Like explained above, this is what tells the cluster to reserve ("claim") the storage from the StorageClass (in this case, `azurefile`). Once this PVC is created and provisioned, it can be used by pods.

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc1
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile
  resources:
    requests:
      storage: 1Gi
```

### Reader pod

This pod mounts the PVC and just loops while reading it.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: pod1
spec:
  containers:
    - name: pod1container
      image: debian:latest
      command: ["/bin/bash"]
      args: ["-c", "while true; do date; cat /var/local/sharedstorage/file1; sleep 5; done"]
      volumeMounts:
        - name: sharedstorage
          mountPath: /var/local/sharedstorage
  volumes:
    - name: sharedstorage
      persistentVolumeClaim:
        claimName: pvc1
```

### Writer pod

This pod also mounts the PVC (which is possible because the PVC is set to be `ReadWriteMany`) and writes to a file in a loop.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: pod2
spec:
  containers:
    - name: pod2container
      image: debian:latest
      command: ["/bin/bash"]
      args: ["-c", "while true; do sleep 15; echo hi from pod2 $(date) >> /var/local/sharedstorage/file1; done"]
      volumeMounts:
        - name: sharedstorage
          mountPath: /var/local/sharedstorage
  volumes:
    - name: sharedstorage
      persistentVolumeClaim:
        claimName: pvc1
```

### Explanation

This is a small example to show how to work with storage that is provisioned from Azure into an AKS cluster, and having multiple pods reading to it and writing from it.

The logs from the reader pod (pod1) show the expected output data from pod2:

```
$ kubectl logs pod1
Mon Aug 31 15:46:03 UTC 2020
cat: /var/local/sharedstorage/file1: No such file or directory
Mon Aug 31 15:46:08 UTC 2020
cat: /var/local/sharedstorage/file1: No such file or directory
Mon Aug 31 15:46:13 UTC 2020
hi from pod2 Mon Aug 31 15:46:12 UTC 2020
Mon Aug 31 15:46:18 UTC 2020
hi from pod2 Mon Aug 31 15:46:12 UTC 2020
Mon Aug 31 15:46:23 UTC 2020
hi from pod2 Mon Aug 31 15:46:12 UTC 2020
Mon Aug 31 15:46:28 UTC 2020
hi from pod2 Mon Aug 31 15:46:12 UTC 2020
hi from pod2 Mon Aug 31 15:46:27 UTC 2020
```

## Summary

Through the usage of built-in StorageClass objects in AKS, you can be up-and-running with cloud-provided storage in your Kubernetes cluster quickly and easily. With some basic understanding of the moving parts of storage, you can make the right decisions for your Kubernetes-hosted software.
