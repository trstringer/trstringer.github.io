---
layout: post
title: Helm Hooks Are An Anti-Pattern and Should Be Avoided
categories: [Blog]
tags: [kubernetes,helm]
---

Helm has been at the heart of Kubernetes deployments for years. If you are managing any amount of Kubernetes clusters, then you have likely already installed a Helm chart in your environment. And for a good reason, too. It's a great way to distribute software manifests to the community.

[Hooks](https://helm.sh/docs/topics/charts_hooks/) are a common feature in Helm, which allow you to take an action in part of the chart lifecycle. For example, *before the templates are installed, do this thing.* There are a handful of events that you can hook into, including `pre-install`, `post-install`, `pre-upgrade`, and many more (refer to the documentation for the complete list).

While this sounds like a great feature, I think that they should be avoided in *most* cases (I'm not a big fan of "always" and "never". I'm sure there are valid reasons and times for Helm hooks). Here are a few reasons why I don't like hooks...

## Declarative becomes imperative

It is a powerful thing to be able to work with declarative infrastructure and applications. Essentially you are saying, "here is the desired state of my software... make it happen." This is (mostly) the case with Kubernetes and Helm, but when we introduce hooks we're essentially changing that declarative desired end state and injecting imperative implementation. Best case scenario, this can be confusing to reason about (especially to somebody that isn't a Helm expert). Worst case scenario, things don't happen when they were intended to in common execution scenarios, as we'll see below.

## You are forced to use Helm

Hooks are great and wonderful, and work amazingly... if you use Helm to manage your Kubernetes resources. What I mean by that is letting Helm do all the Helm things because you did a `helm install` of the chart in your cluster:

```
$ helm install hooks-test ./hooks-test
NAME: hooks-test
LAST DEPLOYED: Sun Nov  5 08:37:25 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Helm is managing this installation (failures, upgrades, etc.):

```
$ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
hooks-test      default         1               2023-11-05 08:37:25.67544664 -0500 EST  deployed        hooks-test-0.1.0        1.16.0 
```

**But... what if you don't want Helm to manage your application?** That's the problem with hooks. If you don't want to have Helm manage your resources, a common way to install your chart's Kubernetes resources is to generate the templates, and then apply those templates.

```
$ helm template hooks-test ./hooks-test | kubectl apply -f -
```

Many other tools have the ability to do this (e.g. Pulumi), and that's a completely valid approach.

## What can go wrong

Let's see what can happen with an actual concrete example with hooks if you *don't* use Helm to install your application. I created a Helm hook that just sleeps for a little bit and then creates a ConfigMap:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hook
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "4"
spec:
  template:
    metadata:
      name: hook
    spec:
      serviceAccountName: kubectl
      restartPolicy: OnFailure
      containers:
        - name: kubectl
          image: ghcr.io/trstringer/kubectl:latest
          command: ["/bin/bash"]
          args: ["-c", "sleep 10 && kubectl create cm hello-world"]
```

This hook is a `pre-install` hook, so it will be applied *before* templates are rendered. And one of those templates is my application:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app1
spec:
  serviceAccountName: kubectl
  restartPolicy: Never
  containers:
    - name: kubectl
      image: ghcr.io/trstringer/kubectl:latest
      command: ["/bin/bash"]
      args: ["-c", "kubectl get cm hello-world && sleep infinity"]
```

In this contrived example, the application just gets the ConfigMap and sleeps. If I `helm install` this chart, what happens?

```
$ helm install hooks-test ./hooks-test
```

The hook job is created and does its work:

```
configmap/hello-world created
```

And this all happens *before* the application starts up. And when that application pod finally starts up, the ConfigMap exists. Here is the application pod logs, show it succeeded:

```
NAME          DATA   AGE
hello-world   0      4s
```

But now let's say I don't want to use `helm install`, but instead I want to get and apply the templates:

```
helm template hooks-test ./hooks-test --output-dir ./out
for MANIFEST in ./out/hooks-test/templates/*.yaml; do
    kubectl apply -f $MANIFEST
done
```

Both the hook job *and* the application pod are created at the same time. Because of this lack of lifecycle management, the application fails because the ConfigMap doesn't exist yet (the hook job hasn't created it yet):

```
Error from server (NotFound): configmaps "hello-world" not found
```

Templating out the Helm chart has essentially broken this application, because there is no notion of hooks from a template.

## The solution

So if that's the problem, what *should* we be doing? It's the real world, and resource dependencies are a very real thing. Instead of relying on Helm hooks, I think we should be using Kubernetes-native implementations to enforce lifecycle. Let's refactor our application:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app2
spec:
  serviceAccountName: kubectl
  restartPolicy: Never
  initContainers:
    - name: wait-for-cm
      image: ghcr.io/trstringer/kubectl:latest
      command: ["/bin/bash"]
      args: ["-c", "echo Waiting for ConfigMap; while ! kubectl get cm hello-world; do echo Missing ConfigMap, sleeping...; sleep 2; done"]
  containers:
    - name: kubectl
      image: ghcr.io/trstringer/kubectl:latest
      command: ["/bin/bash"]
      args: ["-c", "kubectl get cm hello-world && sleep infinity"]
```

Here I've added a simple init container that prevents the application container from starting up until a certain condition is met (in this case, until the ConfigMap exists).

```
$ kubectl get po
NAME   READY   STATUS     RESTARTS   AGE
app2   0/1     Init:0/1   0          2s
```

We can see that this init container just loops waiting for the condition to be met:


```
Error from server (NotFound): configmaps "hello-world" not found
Missing ConfigMap, sleeping...
Error from server (NotFound): configmaps "hello-world" not found
Missing ConfigMap, sleeping...
Error from server (NotFound): configmaps "hello-world" not found
Missing ConfigMap, sleeping...
Error from server (NotFound): configmaps "hello-world" not found
Missing ConfigMap, sleeping...
```

And when the hook job pod finally runs and completes, the init container completes and the application container starts up:

```
$ kubectl get po
NAME         READY   STATUS      RESTARTS   AGE
app2         1/1     Running     0          47s
hook-c5r8l   0/1     Completed   0          23s
```

Great! Now with init containers we've enforced the dependency cycle, all with Kubernetes-native implementations. Now it doesn't matter if this chart is installed with `helm install`, `helm template`, or any other way!

## Summary

At first glance, Helm hooks seem really great. But they add a massive limiting factor to how a chart could be installed into the cluster and we should probably be taking other approaches!
