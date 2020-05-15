---
layout: post
title: Running kubectl Commands From Within a Pod
categories: [Blog]
tags: [kubernetes]
---

It is common to work with Kubernetes resources from *within* internal pods. The platform is obviously a great scheduler and orchestrator, but you may have custom logic that needs to make decisions from, or decisions for, Kubernetes resources.

This post will use a simple example. Say you have the requirement to list out all of the pods, but you need to do this from pods in the cluster (maybe you have to programmatically make decisions based on the state of resources). Here's a simple Dockerfile for a sample image...

### Dockerfile

```
FROM debian:buster

RUN apt update && \
      apt install -y curl && \
      curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
      chmod +x ./kubectl && \
      mv ./kubectl /usr/local/bin/kubectl

CMD kubectl get po
```

This is a way to create a docker image that includes the `kubectl` bin. And then finally any container created from this image will just run `kubectl get po`.

Your instinct might be to create a pod with the following config...

### pod.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: internal-kubectl
spec:
  containers:
    - name: internal-kubectl
      image: trstringer/internal-kubectl:latest
```

Attempting to run this pod (`$ kubectl apply -f pod.yaml`), you would see the following error from the logs...

> Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"

Unless specified otherwise (like above), pods will run under the `default` service account, which is out-of-the-box for each namespace. As you can tell by the error message, `default` doesn't have the right permissions to list the pods.

The underlying force that is preventing us, and that we need to configure correctly, is [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/). The way to tell Kubernetes that we want this pod to have an identity that can list the pods is through the combination of a few different resources...

### service-account.yaml

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: internal-kubectl
```

The identity object that we want to assign to our pod will be a service account. But by itself it has no permissions. That's where roles come in.

### role.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: modify-pods
rules:
  - apiGroups: [""]
    resources:
      - pods
    verbs:
      - get
      - list
      - delete
```

The role above specifies that we want to be able to get, list, and delete pods. But we need a way to correlate our new service account with our new role. Role bindings are the bridges for that...

### role-binding.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: modify-pods-to-sa
subjects:
  - kind: ServiceAccount
    name: internal-kubectl
roleRef:
  kind: Role
  name: modify-pods
  apiGroup: rbac.authorization.k8s.io
```

This role binding connects our service account to the role that has the permissions we need. Now we just have to modify our pod config to include the service account...

### pod.yaml (new)

```
apiVersion: v1
kind: Pod
metadata:
  name: internal-kubectl
spec:
  serviceAccountName: internal-kubectl
  containers:
    - name: internal-kubectl
      image: trstringer/internal-kubectl:latest
```

By specifying `spec.serviceAccountName` this changes us from using the `default` service account to our new one that has the correct permissions. Running our new pod we should see the correct output...

```
 $ kubectl logs internal-kubectl
NAME               READY   STATUS    RESTARTS   AGE
internal-kubectl   1/1     Running   1          5s
```

Enjoy!
