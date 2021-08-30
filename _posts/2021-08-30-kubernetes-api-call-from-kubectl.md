---
layout: post
title: Discover Kubernetes API Calls from kubectl
categories: [Blog]
tags: [kubernetes]
---

It's a rare occurrence, but there may be a time when you need to make a direct call to the Kubernetes API server to do something. Or maybe you are just curious about the REST API and what's happening under the covers!

The Kubernetes docs do a great job on showing the first step [how to get the token and curl the API](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/#without-kubectl-proxy), but how do you start discovering the different API calls for different operations?

The answer is through `kubectl`. Add verbose logging level of 8+ and you will get the API calls!

Let's see this in action. Say you want to get the Kubernetes API call to get all of the pods in the default namespace:

```
$ kubectl get pods -v=8
```

The output contains a *lot* of information:

```
I0827 06:51:49.950850    8021 loader.go:375] Config loaded from file:  /home/trstringer/.kube/config
I0827 06:51:49.954797    8021 round_trippers.go:420] GET https://myapiserver:443/api/v1/namespaces/default/pods?limit=500
I0827 06:51:49.954817    8021 round_trippers.go:427] Request Headers:
I0827 06:51:49.954821    8021 round_trippers.go:431]     Accept: application/json;as=Table;v=v1;g=meta.k8s.io,application/json;as=Table;v=v1beta1;g=meta.k8s.io,application/json
I0827 06:51:49.954826    8021 round_trippers.go:431]     User-Agent: kubectl/v1.19.0 (linux/amd64) kubernetes/e199641
I0827 06:51:49.954831    8021 round_trippers.go:431]     Authorization: Bearer <masked>
I0827 06:51:50.141125    8021 round_trippers.go:446] Response Status: 200 OK in 186 milliseconds
I0827 06:51:50.141185    8021 round_trippers.go:449] Response Headers:
I0827 06:51:50.141197    8021 round_trippers.go:452]     Cache-Control: no-cache, private
I0827 06:51:50.141206    8021 round_trippers.go:452]     Content-Type: application/json
I0827 06:51:50.141214    8021 round_trippers.go:452]     X-Kubernetes-Pf-Flowschema-Uid: ac1def70-6b11-457d-a19a-79b2e24d3a65
I0827 06:51:50.141226    8021 round_trippers.go:452]     X-Kubernetes-Pf-Prioritylevel-Uid: 954e3926-9429-459a-bdc3-267ebd39a141
I0827 06:51:50.141309    8021 round_trippers.go:452]     Content-Length: 2880
I0827 06:51:50.141328    8021 round_trippers.go:452]     Date: Fri, 27 Aug 2021 10:51:50 GMT
I0827 06:51:50.141334    8021 round_trippers.go:452]     Audit-Id: dc2bcab3-534e-45d5-8eea-aec00874df07
I0827 06:51:50.141381    8021 request.go:1097] Response Body: {"kind":"Table","apiVersion":"meta.k8s.io/v1","metadata":{"resourceVersion":"2035"},"columnDefinitions":[{"name":"Name","type":"string","format":"name","description":"Name must be unique within a namespace. Is required when creating resources, although some resources may allow a client to request the generation of an appropriate name automatically. Name is primarily intended for creation idempotence and configuration definition. Cannot be updated. More info: http://kubernetes.io/docs/user-guide/identifiers#names","priority":0},{"name":"Ready","type":"string","format":"","description":"The aggregate readiness state of this pod for accepting traffic.","priority":0},{"name":"Status","type":"string","format":"","description":"The aggregate status of the containers in this pod.","priority":0},{"name":"Restarts","type":"integer","format":"","description":"The number of times the containers in this pod have been restarted.","priority":0},{"name":"Age","type":"string","format":"","description":"CreationTimestamp is a [truncated 1856 chars]
No resources found in default namespace.
```

We see a lot of interesting things here, but we are curious about the API call which we can find on the second line. So now we know the API call to get all pods in the `default` namespace is a `GET` on `api/v1/namespaces/default/pods`.

Let's see another example: Find all services in the cluster with the label `component=apiserver`.

```
$ kubectl get services --all-namespaces -l component=apiserver -v=8
```

Looking through the output we can see that the API call is a `GET` on `api/v1/services?labelSelector=component%3Dapiserver`.

What about if you want to create or modify a Kubernetes resource? You can still do the same thing as above, but there's a good chance you don't want kubectl doing the creation or modification. You might just want kubectl to tell you the API call, but don't do it. We can add the parameter `--dry-run=server` to get this information *without* modifying anything!

Another example: Find out the API call to create a namespace, without creating the namespace.

```
$ kubectl create namespace test --dry-run=server -v=8
```

We can see with the output that it is a `POST` on `api/v1/namespaces` with the request body of `{"apiVersion":"v1","kind":"Namespace","metadata":{"creationTimestamp":null,"name":"test"},"spec":{},"status":{}}`.

And since this was a dry run, the namespace wasn't created.

Hopefully this blog post has showed you a quick and easy way to get the Kubernetes API calls for any operation you can run through kubectl!
