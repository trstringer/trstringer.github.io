---
layout: post
title: Kubernetes’ AlwaysPullImages Admission Control - the Importance, Implementation, and Security Vulnerability in its Absence
categories: [Blog]
tags: [kubernetes,devops,security]
---

Kubernetes is big and only getting bigger. What this means is that as adoption is on the rise, the natural progression is more Kubernetes clusters thrust into production. Oftentimes security is an afterthought.

One of the lesser-known security implications of Kubernetes is dealing with the image pull policy, which strongly influences if/how cached image consumption could be a workaround to image security. This is primarily a concern on multi-tenant Kubernetes clusters, but even if you are the only cluster operator today, it is still something to be familiar with.

## What are admission controls?

In a Kubernetes cluster, admission controls are ways to inject extra handling when creating and working with resources. There are two types of admission controls: Validating and mutating. You can think of them as “checks” (validation) and “changes” (mutation).

There is an exhaustive list of all possible admission controls available on the [official Kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#what-does-each-admission-controller-do). The one that we are focusing on in this blog post is the [AlwaysPullImages admission control](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#alwayspullimages).

## Enabling the AlwaysPullImages admission control

Flipping the switch for an admission control plugin is done by specifying your desired admission control plugin directly in the kube-apiserver parameters for the cluster.

In Kubernetes clusters v1.9 and below this parameter is --admission-control followed by a comma-delimited list of all admission control plugins you wish to enable (Note: order matters!). For more information, please refer to the official documentation.

Starting in Kubernetes v1.10 this parameter is renamed to --enable-admission-plugins and order does not matter. For more information, please refer to the [official documentation](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller).

## What does it do? An illustration...

When the AlwaysPullImages admission control plugin is enabled in a cluster, this forces the image pull policy to be set to **Always**, no matter how it is specified when creating the resource.

Take, for instance, the following simple pod manifest for nginx:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-image-pull-policy
spec:
  containers:
    - name: nginx
      image: nginx:1.13
      imagePullPolicy: IfNotPresent
```

I explicitly set the `imagePullPolicy` to `IfNotPresent`, which would normally tell the kubelet to only pull the image from the container registry if it is not already cached on the node. If it is cached on the node, use the cached image (we’ll take a look below at how this could be a huge security problem). But with the AlwaysPullImages plugin enabled on my cluster, take a look at what the effective image pull policy is (creating the namespace and pod, and then running discovery)...

```bash
$ kubectl create ns imgpullpolicy 
$ kubectl apply -f image_pull_policy_pod.yaml -n imgpullpolicy 
$ kubectl get po -n imgpullpolicy test-image-pull-policy -o jsonpath=”{.spec.containers[0].imagePullPolicy}” 
Always
```

Kubernetes mutated the `imagePullPolicy` to `Always` even though we tried to use a cached version. Now no matter what the creator has indicated for the image pull policy, our cluster will enforce that we cannot use any cached images.

## What can happen if you don’t have AlwaysPullImages set?

We’ve spent some time talking about how to enable AlwaysPullImages, and what exactly it does. But there is a lot of value in talking about what the actual security concern is in the absence of AlwaysPullImages. I think the best way is to walk through what could happen in the absence of AlwaysPullImages:

1. **Admin1** creates **Pod1** that uses **SuperSecretImage1** by specifying **ImagePullSecret1** to gain access to the **SecureContainerRegistry** holding the image.
1. Kubernetes pulls down and caches **SuperSecretImage1** on the node and then creates **Pod1** accordingly.
1. **Admin2**, who does not have access to **ImagePullSecret1** or **SecureContainerRegistry**, attempts to create **Pod2** using **SuperSecretImage1** and an **imagePullPolicy** of **IfNotPresent**. Because this image is cached on the node, this operation is successful.

Admin2 should not be able to consume SuperSecretImage1, but uses a cached image to circumvent the container registry security. This is the problem that AlwaysPullImages admission control solves.

Here is what step #3 would look like if AlwaysPullImages is enabled on the cluster...

**Admin2**, who does not have access to **ImagePullSecret1** or **SecureContainerRegistry**, attempts to create **Pod2** using **SuperSecretImage1** and an **imagePullPolicy** of **IfNotPresent**. The AlwaysPullImages admission hook mutates the imagePullPolicy to Always, and then the necessary and appropriate security checks are done and **Admin2** will not successfully retrieve the **SuperSecretImage1** and deploy **Pod2**.

## Image security doesn’t stop at Kubernetes

Security is oftentimes many layers deep and image security in Kubernetes is no different. Even with AlwaysPullImages enabled on the cluster, if an unauthorized user has access to the underlying machines that the Kubernetes cluster runs on, they could SSH into a node and save the image directly to a file again circumventing the container registry security. Keep this in mind when you are deciding whether or not to give a user access to the cluster machines!

## Summary

Knowing how Kubernetes works with container images is important not only for getting something up and running, but also being able to securely work in a distributed environment. Keeping security always in focus will minimize vulnerabilities and ensure that a user or process that shouldn’t access something... can’t.
