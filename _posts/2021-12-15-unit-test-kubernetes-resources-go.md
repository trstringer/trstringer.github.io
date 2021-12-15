---
layout: post
title: Unit Testing Kubernetes Resources with Go
categories: [Blog]
tags: [kubernetes,golang]
---

In the previous blog post I talked about [how to connect to a Kubernetes cluster from Go](https://trstringer.com/connect-to-kubernetes-from-go/). But we're missing something here with this solution: Unit tests. These blogs posts use contrived examples (getting pods, showing labels, etc.) but your software likely is more complex, and there is a low bar for the requirements of testing your code. Go makes that relatively painless to write unit tests. But... how do we unit test our code that accesses a Kubernetes cluster? After all, unit tests should be runnable without having any external dependencies (like a Kubernetes cluster).

The answer is that Kubernetes provides fake clientsets. Let's see what that looks like!

## The application code

*Note: I'm going to first introduce the main runnable application, so if you're just interested in how to test it feel free to skip this section and jump down.*

This application is a simple example on how to get a pod's label in a Kubernetes cluster. It will then uppercase the label's value. Here's the code in its entirety:

**main.go**

```go
package main

import (
        "context"
        "fmt"
        "os"
        "path/filepath"
        "strings"

        v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
        "k8s.io/client-go/kubernetes"
        "k8s.io/client-go/tools/clientcmd"
)

func uppercasePodLabel(clientset kubernetes.Interface, namespace, podName, labelKey string) (string, error) {
        pod, err := clientset.CoreV1().Pods(namespace).Get(
                context.Background(),
                podName,
                v1.GetOptions{},
        )
        if err != nil {
                return "", err
        }

        labelValue, ok := pod.ObjectMeta.Labels[labelKey]
        if !ok {
                return "", fmt.Errorf("no label with key %s for pod %s/%s", labelKey, namespace, podName)
        }
        return strings.ToUpper(labelValue), nil
}

func main() {
        fmt.Println("Get Kubernetes pod label to uppercase")

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

        labelValue, err := uppercasePodLabel(clientset, "default", "testpod1", "hello")
        if err != nil {
                fmt.Printf("error getting pod label: %v\n", err)
                os.Exit(1)
        }
        fmt.Printf("Pod label value: %s\n", labelValue)
}
```

This code just connects to the local Kubernetes cluster and gets a particular pod ("default/testpod1") and it's label ("hello") value. It will then uppercase the label value. Let's see this in action with an actual Kubernetes cluster:

**test-pod.yaml**

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: testpod1
  labels:
    hello: world
spec:
  containers:
    - name: ubuntu
      image: ubuntu:focal
      command: ["/bin/bash"]
      args: ["-c", "sleep infinity"]
```

Now that we have our target pod created, let's run the application:

```
$ go run .
Get Kubernetes pod label to uppercase
Using kubeconfig: /home/trstringer/.kube/config
Pod label value: WORLD
```

Great! It works as expected. But how can we test this?

## Writing a unit test

From the code above, you will notice that we should be unit testing the `uppercasePodLabel` function. It's not a very complicated function, but in a real-world scenario we definitely want to make sure a function like this does what we expect it to do. How does it handle a situation when the pod is not found? How does it handle the situation when the label isn't found? Let's test out our expectations.

The answer with that is to use a fake clientset. In this case we are targeting the core API group, so the fake clientset can be referenced from `k8s.io/client-go/kubernetes/fake`. When we create our fake clientset, we will *inject* the resources for that clientset that we want to be available. This allows us to no longer depend on the Kubernetes cluster, because we are injecting the dependencies directly. To do this we'll call `fake.NewSimpleCientset` and pass in zero or more `runtime.Object` instances. Let's see how this looks.

*Note: The following test uses a template testing strategy. I really like this testing approach because it allows you to have a single unit test for a testable part of code but with multiple variations and multiple expectations for different scenarios.*

**main_test.go**

```go
package main

import (
        "testing"

        corev1 "k8s.io/api/core/v1"
        metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
        "k8s.io/apimachinery/pkg/runtime"
        "k8s.io/client-go/kubernetes/fake"
)

func TestLabelUpperCase(t *testing.T) {
        testCases := []struct {
                name               string
                pods               []runtime.Object
                targetNamespace    string
                targetPod          string
                targetLabelKey     string
                expectedLabelValue string
                expectSuccess      bool
        }{
                {
                        name: "existing_pod_found",
                        pods: []runtime.Object{
                                &corev1.Pod{
                                        ObjectMeta: metav1.ObjectMeta{
                                                Name:      "pod1",
                                                Namespace: "namespace1",
                                                Labels: map[string]string{
                                                        "label1": "value1",
                                                },
                                        },
                                },
                        },
                        targetNamespace:    "namespace1",
                        targetPod:          "pod1",
                        targetLabelKey:     "label1",
                        expectedLabelValue: "VALUE1",
                        expectSuccess:      true,
                },
                {
                        name:               "no_pods_existing",
                        pods:               []runtime.Object{},
                        targetNamespace:    "namespace1",
                        targetPod:          "pod1",
                        targetLabelKey:     "label1",
                        expectedLabelValue: "VALUE1",
                        expectSuccess:      false,
                },
                {
                        name: "existing_pod_missing_label",
                        pods: []runtime.Object{
                                &corev1.Pod{
                                        ObjectMeta: metav1.ObjectMeta{
                                                Name:      "pod1",
                                                Namespace: "namespace1",
                                        },
                                },
                        },
                        targetNamespace:    "namespace1",
                        targetPod:          "pod1",
                        targetLabelKey:     "label1",
                        expectedLabelValue: "VALUE1",
                        expectSuccess:      false,
                },
        }

        for _, test := range testCases {
                t.Run(test.name, func(t *testing.T) {
                        fakeClientset := fake.NewSimpleClientset(test.pods...)
                        labelValue, err := uppercasePodLabel(
                                fakeClientset,
                                test.targetNamespace,
                                test.targetPod,
                                test.targetLabelKey,
                        )
                        if err != nil && test.expectSuccess {
                                t.Fatalf("unexpected error getting label: %v", err)
                        } else if err == nil && !test.expectSuccess {
                                t.Fatalf("expected error but received none getting label")
                        } else if labelValue != test.expectedLabelValue && test.expectSuccess {
                                t.Fatalf("label value %s unexpectedly not equal to %s", labelValue, test.expectedLabelValue)
                        } else if labelValue == test.expectedLabelValue && !test.expectSuccess {
                                t.Fatalf("label values are unexpectedly equal: %s", labelValue)
                        }
                })
        }
}
```

So breaking this down, our first testing template checks for the normal scenario where there is an existing pod with the label:

```go
{
	name: "existing_pod_found",
	pods: []runtime.Object{
		&corev1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      "pod1",
				Namespace: "namespace1",
				Labels: map[string]string{
					"label1": "value1",
				},
			},
		},
	},
	targetNamespace:    "namespace1",
	targetPod:          "pod1",
	targetLabelKey:     "label1",
	expectedLabelValue: "VALUE1",
	expectSuccess:      true,
},
```

You can see that we've contructed the `pods` accordingly as well as the expected outcome. The next templated run is when there are no pods existing, but we will expect this to return an error:

```go
{
	name:               "no_pods_existing",
	pods:               []runtime.Object{},
	targetNamespace:    "namespace1",
	targetPod:          "pod1",
	targetLabelKey:     "label1",
	expectedLabelValue: "VALUE1",
	expectSuccess:      false,
},
```

By setting `expectSuccess` to `false` we are creating the desired end result to have an error. Last we want to test a situation where the pod exists but it doesn't have the right label:

```go
{
	name: "existing_pod_missing_label",
	pods: []runtime.Object{
		&corev1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      "pod1",
				Namespace: "namespace1",
			},
		},
	},
	targetNamespace:    "namespace1",
	targetPod:          "pod1",
	targetLabelKey:     "label1",
	expectedLabelValue: "VALUE1",
	expectSuccess:      false,
},
```

In this case we expect this to also fail with an error. Now that we have our testing templates defined, let's loop through them and run the actual tests:

```go
fakeClientset := fake.NewSimpleClientset(test.pods...)
labelValue, err := uppercasePodLabel(
	fakeClientset,
	test.targetNamespace,
	test.targetPod,
	test.targetLabelKey,
)
if err != nil && test.expectSuccess {
	t.Fatalf("unexpected error getting label: %v", err)
} else if err == nil && !test.expectSuccess {
	t.Fatalf("expected error but received none getting label")
} else if labelValue != test.expectedLabelValue && test.expectSuccess {
	t.Fatalf("label value %s unexpectedly not equal to %s", labelValue, test.expectedLabelValue)
} else if labelValue == test.expectedLabelValue && !test.expectSuccess {
	t.Fatalf("label values are unexpectedly equal: %s", labelValue)
}
```

The first thing we do is create our fake clientset with a call to `fake.NewSimpleClientset`. We'll pass our runtime objects to inject our pods (if there are any) into the fake. Next we'll make a call to our `uppercasePodLabel` function. Finally we'll do four tests to check the error with the `expectSuccess` of the current test and then subsequently testing the expected and actual label values also with the expected success.

Running these tests:

```
$ go test -v ./...
=== RUN   TestLabelUpperCase
=== RUN   TestLabelUpperCase/existing_pod_found
=== RUN   TestLabelUpperCase/no_pods_existing
=== RUN   TestLabelUpperCase/existing_pod_missing_label
--- PASS: TestLabelUpperCase (0.00s)
    --- PASS: TestLabelUpperCase/existing_pod_found (0.00s)
    --- PASS: TestLabelUpperCase/no_pods_existing (0.00s)
    --- PASS: TestLabelUpperCase/existing_pod_missing_label (0.00s)
PASS
ok      connect-to-kubernetes-from-go   (cached)
```

Everything passes, and we now have pretty good coverage of our application logic code with our unit test!

## Summary

It's no mystery that testing our code is important. When your code starts to interact with external dependencies (like a Kubernetes cluster or a database) it can be a bit more challenging. Modeling your code with dependency injection in mind and utilizing fakes (like the Kubernetes fake clientset) can allow us to unit test our code effectively!
