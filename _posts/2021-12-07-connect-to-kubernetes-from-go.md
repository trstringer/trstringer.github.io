---
layout: post
title: Connect to Kubernetes from Go
categories: [Blog]
tags: [kubernetes,golang]
---

You may have a requirement that you need to connect to a Kubernetes cluster from your Go application. Thankfully the Kubernetes team provides a way to do that with [client-go](https://github.com/kubernetes/client-go). But how can you use this to connect to the cluster?

There is a slight difference if your code will be running external or internal to the cluster. Let's take a look at these different approaches.

## Connect from outside of the cluster

To connect to your Kubernetes cluster, you can do something similar:

```golang
package main

import (
        "context"
        "fmt"
        "os"
        "path/filepath"

        v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
        "k8s.io/client-go/kubernetes"
        "k8s.io/client-go/tools/clientcmd"
)

func main() {
        fmt.Println("Get Kubernetes pods")

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

        clientset, err := kubernetes.NewForConfig(kubeConfig)
        if err != nil {
                fmt.Printf("error getting Kubernetes clientset: %v\n", err)
                os.Exit(1)
        }

        pods, err := clientset.CoreV1().Pods("kube-system").List(context.Background(), v1.ListOptions{})
        if err != nil {
                fmt.Printf("error getting pods: %v\n", err)
                os.Exit(1)
        }
        for _, pod := range pods.Items {
                fmt.Printf("Pod name: %s\n", pod.Name)
        }
}
```

Walking through this, we first need to get our Kubernetes config:

```golang
userHomeDir, err := os.UserHomeDir()
if err != nil {
        fmt.Printf("error getting user home dir: %v\n", err)
        os.Exit(1)
}
kubeConfigPath := filepath.Join(userHomeDir, ".kube", "config")
```

In my case here I just assume that it is located in `~/.kube/config`. That is the default, but if you want to have some flexibility to your config location you will likely use a flag to override the default.

Now we can create the config object:

```golang
kubeConfig, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
```

With the config, we can create the clientset:

```golang
clientset, err := kubernetes.NewForConfig(kubeConfig)
if err != nil {
        fmt.Printf("error getting Kubernetes clientset: %v\n", err)
        os.Exit(1)
}
```

Finally, once you have the clientset you can access different API groups and resource types. In my case for this example I just list the pods in the `kube-system` namespace:

```golang
pods, err := clientset.CoreV1().Pods("kube-system").List(context.Background(), v1.ListOptions{})
if err != nil {
        fmt.Printf("error getting pods: %v\n", err)
        os.Exit(1)
}
for _, pod := range pods.Items {
        fmt.Printf("Pod name: %s\n", pod.Name)
}
```

The output is as expected:

```
Get Kubernetes pods
Using kubeconfig: /home/trstringer/.kube/config
Pod name: coredns-558bd4d5db-77b5b
Pod name: coredns-558bd4d5db-sskcx
Pod name: etcd-kind-control-plane
Pod name: kindnet-xg859
Pod name: kube-apiserver-kind-control-plane
Pod name: kube-controller-manager-kind-control-plane
Pod name: kube-proxy-vpp5d
Pod name: kube-scheduler-kind-control-plane
```

## Connect from inside the cluster

The only different when connecting from *within* the cluster is how the config is retrieved. You will use `k8s.io/client-go/rest` and make a call to `rest.InClusterConfig()`. After error checking, pass that config output to `kubernetes.NewForConfig()` and the rest of the code is the same.

It's common to have some logic to first try to connect as if the application is inside the cluster and if that fails attempt to connect as an external process.

## Summary

With client-go you can easily connect your Go code to Kubernetes. Next time we'll look at how to test this type of code!
