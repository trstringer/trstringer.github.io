---
layout: post
title: Deploy Istio Egress Gateway After Installation
categories: [Blog]
tags: [kubernetes,istio]
---

When working with Istio, it's common to kick off a new installation with the default profile:

```
$ istioctl install -y
✔ Istio core installed                                                                                                                                                   
✔ Istiod installed                                                                                                                                                       
✔ Ingress gateways installed                                                                                                                                             
✔ Installation complete                                                                                                                                                  
Making this installation the default for injection and validation.
```

As you can see, Istio installed an ingress gateway:

```
$ kubectl get po -A -l istio=ingressgateway
NAMESPACE      NAME                                    READY   STATUS    RESTARTS   AGE
istio-system   istio-ingressgateway-677f4f9cc4-xks8k   1/1     Running   0          59s
```

But there is no egress gateway from this profile:

```
$ kubectl get po -A -l istio=egressgateway
No resources found
```

This is because the default profile doesn't have it enabled (`kubectl get io -n istio-system installed-state -o yaml`):

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: installed-state
  namespace: istio-system
spec:
  profile: default
  components:
    egressGateways:
    - enabled: false
      name: istio-egressgateway

# Rest of configuration removed for brevity...
```

In the event that you *do* want the egress gateway, though, you just need to create another `IstioOperator`:

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: egress
  namespace: istio-system
spec:
  profile: empty
  values:
    gateways:
      istio-egressgateway:
        injectionTemplate: gateway
  components:
    egressGateways:
    - name: istio-egressgateway
      namespace: istio-system
      enabled: true
      label:
        istio: egressgateway
```

Here we specify the "empty" profile, because we don't need the control plane or any CRDs installed with this (they are already there!). But we do add the egress gateway by specifying it's name and label (and `enabled: true`). Then we specify the `injectionTemplate` to be set to `template`. Once this manifest is created, we can install it similar to how we did the initial installation, but this time passing this file:

```
$ istioctl install -y -f ./istio-egress.yaml
✔ Egress gateways installed
✔ Installation complete
```

Just like with any other installation, it is a good idea to verify this afterwards:

```
$ istioctl verify-install -f ./istio-egress.yaml
✔ HorizontalPodAutoscaler: istio-egressgateway.istio-system checked successfully
✔ Deployment: istio-egressgateway.istio-system checked successfully
✔ PodDisruptionBudget: istio-egressgateway.istio-system checked successfully
✔ Role: istio-egressgateway-sds.istio-system checked successfully
✔ RoleBinding: istio-egressgateway-sds.istio-system checked successfully
✔ Service: istio-egressgateway.istio-system checked successfully
✔ ServiceAccount: istio-egressgateway-service-account.istio-system checked successfully
✔ IstioOperator: egress.istio-system checked successfully
Checked 0 custom resource definitions
Checked 1 Istio Deployments
✔ Istio is installed and verified successfully
```

And now we should see our egress gateway in the cluster!

```
$ kubectl get po -A -l istio=egressgateway
NAMESPACE      NAME                                   READY   STATUS    RESTARTS   AGE
istio-system   istio-egressgateway-5bf66588fc-kqdvh   1/1     Running   0          88s
```

Hopefully this blog post has helped you how you can install the Istio egress gateway even *after* the initial service mesh installation!
