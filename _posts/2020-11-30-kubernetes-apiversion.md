---
layout: post
title: Find Which apiVersion to Use for Kubernetes Resources
categories: [Blog]
tags: [kubernetes]
---

When creating Kubernetes resource manifests, one of the first things that we need to specify for the resource is the `apiVersion`. For many of the common resources, you might be able to "guess" accurately, but it's a good skill to be able to figure this out in your cluster.

The format of the `apiVersion` is `api_group/version` (unless you are working with resource in the core API group, in which case you omit the `api_group` portion). So we need to break this short process into two steps:

1. Find out the API group that the resource type belongs to.
1. And then find out the version in the cluster for this API group.

## Find the API group

The first step in deterministically constructing the `apiVersion` for your new Kubernetes resource is to find out what API group that it belongs to. This can be found with `kubectl api-resources`:

```
$ kubectl api-resources
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND
bindings                                                                      true         Binding
configmaps                        cm                                          true         ConfigMap
endpoints                         ep                                          true         Endpoints
namespaces                        ns                                          false        Namespace
nodes                             no                                          false        Node
deployments                       deploy       apps                           true         Deployment
replicasets                       rs           apps                           true         ReplicaSet
statefulsets                      sts          apps                           true         StatefulSet
cronjobs                          cj           batch                          true         CronJob
jobs                                           batch                          true         Job
```

*Output omitted for brevity.*

The data we're looking for is the third column, `APIGROUP`. If, for example, you're creating a manifest for a new `Deployment` you could `grep` the output of `kubectl api-resources` and see that the API group is `apps`.

## Get the API group version

Now that we know the API group (in the above example, `apps`), we need to get the verion(s) that exist in our target cluster.

This information can be found through `kubectl api-versions`. It's easiest to filter this output for your specific API group:

```
$ kubectl api-versions | grep -E "^apps/"
apps/v1
```

And the returned output should be the version that we should target.

## Summary

So now when constructing the `apiVersion` for a new `Deployment` in this cluster, we know that it should be `apps/v1`:

```yaml
kind: Deployment
apiVersion: apps/v1
...
```

Next time, don't guess for the API version! Run a few commands to quickly discovery what it should be set to.
