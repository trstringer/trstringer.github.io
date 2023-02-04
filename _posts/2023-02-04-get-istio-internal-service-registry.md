---
layout: post
title: Get Istio's Internal Service Registry
categories: [Blog]
tags: [istio,kubernetes]
---

Istio maintains an internal service registry that it uses to configure the data plane proxies. This service registry is the center of a lot of operations: For instance, when dealing with external traffic, which is essentially endpoints that don't exist in the service registry, Istio will either block or allow based off of few different settings (`meshConfig.outboundTrafficPolicy.mode` will either allow with `ALLOW_ANY` or prevent external access with `REGISTRY_ONLY`).

When troubleshooting or diagnosing issues in Istio, it can be helpful to be able to see exactly *what* this internal service registry is. Thankfully, we can access this data through the following Pilot endpoint:

```
/debug/registryz
```

Let's list out a service registry from a sample cluster I have:

```bash
$ PILOT_NAMESPACE=istio-system
$ PILOT_POD_NAME=$(kubectl get po -n $PILOT_NAMESPACE -l istio=pilot -o jsonpath='{.items[0].metadata.name}')

$ kubectl exec -n $PILOT_NAMESPACE $PILOT_POD_NAME -- curl localhost:15014/debug/registryz | jq '.[].hostname' -r
httpbin2.default.svc.cluster.local
istio-egressgateway.istio-system.svc.cluster.local
istiod.istio-system.svc.cluster.local
kube-dns.kube-system.svc.cluster.local
kubernetes.default.svc.cluster.local
metrics-server.kube-system.svc.cluster.local
```

In my case, I piped this into `jq` and queried only the hostnames, but there is a ton more valid information that you might want to see. Here is the service registry entry for the httpbin2 service:

```json
{
  "Attributes": {
    "ServiceRegistry": "Kubernetes",
    "Name": "httpbin2",
    "Namespace": "default",
    "Labels": null,
    "ExportTo": null,
    "LabelSelectors": {
      "app": "httpbin2"
    },
    "ClusterExternalAddresses": {
      "Addresses": null
    },
    "ClusterExternalPorts": null
  },
  "ports": [
    {
      "name": "http",
      "port": 80,
      "protocol": "HTTP"
    }
  ],
  "creationTime": "2023-02-04T14:59:57Z",
  "hostname": "httpbin2.default.svc.cluster.local",
  "clusterVIPs": {
    "Addresses": {
      "Kubernetes": [
        "10.0.158.176"
      ]
    }
  },
  "defaultAddress": "10.0.158.176",
  "Resolution": 0,
  "MeshExternal": false,
  "ResourceVersion": "3656"
}
```

Since this is the internal service registry, it will also include any `ServiceEntry` resources that were created. Let's see what that looks like:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: google
spec:
  hosts:
    - www.google.com
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - name: https
      protocol: TLS
      number: 443
```

With that service entry created, let's look at all the hostnames in the internal service registry now:

```bash
$ kubectl exec -n $PILOT_NAMESPACE $PILOT_POD_NAME -- curl -s localhost:15014/debug/registryz | jq '.[].hostname' -r
www.google.com
httpbin2.default.svc.cluster.local
istio-egressgateway.istio-system.svc.cluster.local
istiod.istio-system.svc.cluster.local
kube-dns.kube-system.svc.cluster.local
kubernetes.default.svc.cluster.local
metrics-server.kube-system.svc.cluster.local
```

Great, now we see our new "service"! The full service registry entry looks like this:

```json
{
  "Attributes": {
    "ServiceRegistry": "External",
    "Name": "www.google.com",
    "Namespace": "default",
    "Labels": null,
    "ExportTo": null,
    "LabelSelectors": null,
    "ClusterExternalAddresses": {
      "Addresses": null
    },
    "ClusterExternalPorts": null
  },
  "ports": [
    {
      "name": "https",
      "port": 443,
      "protocol": "TLS"
    }
  ],
  "creationTime": "2023-02-04T21:39:56Z",
  "hostname": "www.google.com",
  "clusterVIPs": {
    "Addresses": null
  },
  "defaultAddress": "0.0.0.0",
  "autoAllocatedIPv4Address": "240.240.0.1",
  "autoAllocatedIPv6Address": "2001:2::f0f0:1",
  "Resolution": 1,
  "MeshExternal": true,
  "ResourceVersion": ""
}
```

A lot of really great information here, and you can see now that `MeshExternal` is set to `true`.

Hopefully this blog post has shown you how you can quickly look at Istio's internal service registry if you ever need to verify what services Istio knows about!
