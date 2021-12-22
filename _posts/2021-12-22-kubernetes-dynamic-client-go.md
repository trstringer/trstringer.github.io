---
layout: post
title: Unstructured Kubernetes Components with client-go's Dynamic Client
categories: [Blog]
tags: [kubernetes,golang]
---

Recently I've written about [how to access Kubernetes resources from Go](https://trstringer.com/connect-to-kubernetes-from-go/), which works with structured objects. There may be times when you want to work with **unstructured** components though. Recently I needed to do this because I didn't know at compile time the types of objects I would be working with.

Kubernetes provides a [dynamic client from client-go](https://github.com/kubernetes/client-go/tree/master/dynamic) to give you this functionality. You can import the `dynamic` package from `k8s.io/client-go/dynamic`.

Creating the dynamic client can be done like the following:

```go
dynamicClient, err := dynamic.NewForConfig(kubeConfig)
```

We need to create a `GroupVersionResource` from `k8s.io/apimachinery/pkg/runtime/schema`:

```go
gvr := schema.GroupVersionResource{
    Group:    "",
    Version:  "v1",
    Resource: "pods",
}
```

In my sample application I want to list out pods, so the group is the core group which is an empty string. The version is `v1` and the resource is set to `pods`. Now we can list them out:

```go
pods, err := dynamicClient.Resource(gvr).Namespace("kube-system").List(context.Background(), v1.ListOptions{})
if err != nil {
    fmt.Printf("error getting pods: %v\n", err)
    os.Exit(1)
}

for _, pod := range pods.Items {
    fmt.Printf(
        "Name: %s\n",
        pod.Object["metadata"].(map[string]interface{})["name"],
    )
}
```

The unstructured items have a type of `map[string]interface{}`, so as you crawl through the resources and their fields you have to use type assertion.

The full code for this example is below:

```go
package main

import (
        "context"
        "fmt"
        "os"
        "path/filepath"

        v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
        "k8s.io/apimachinery/pkg/runtime/schema"
        "k8s.io/client-go/dynamic"
        "k8s.io/client-go/tools/clientcmd"
)

func main() {
        fmt.Println("Get pod names with the dynamic client")

        userHomeDir, err := os.UserHomeDir()
        if err != nil {
                fmt.Printf("error getting user home dir: %v\n", err)
                os.Exit(1)
        }
        kubeConfigPath := filepath.Join(userHomeDir, ".kube", "config")
        fmt.Printf("Using kubeconfig: %s\n", kubeConfigPath)

        kubeConfig, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
        if err != nil {
                fmt.Printf("error getting Kubernetes config: %v\n", err)
                os.Exit(1)
        }

        dynamicClient, err := dynamic.NewForConfig(kubeConfig)
        if err != nil {
                fmt.Printf("error creating dynamic client: %v\n", err)
                os.Exit(1)
        }

        gvr := schema.GroupVersionResource{
                Group:    "",
                Version:  "v1",
                Resource: "pods",
        }

        pods, err := dynamicClient.Resource(gvr).Namespace("kube-system").List(context.Background(), v1.ListOptions{})
        if err != nil {
                fmt.Printf("error getting pods: %v\n", err)
                os.Exit(1)
        }

        for _, pod := range pods.Items {
                fmt.Printf(
                        "Name: %s\n",
                        pod.Object["metadata"].(map[string]interface{})["name"],
                )
        }
}
```

And the output of running this against a cluster:

```
$ go run .
Get pod names with the dynamic client
Using kubeconfig: /home/trstringer/.kube/config
Name: coredns-558bd4d5db-fwrmj
Name: coredns-558bd4d5db-l2k52
Name: etcd-kind-control-plane
Name: kindnet-46gtb
Name: kube-apiserver-kind-control-plane
Name: kube-controller-manager-kind-control-plane
Name: kube-proxy-5t7c9
Name: kube-scheduler-kind-control-plane
```

Hopefully this blog post has shown how to use the dynamic client to work with unstructured Kubernetes resources!
