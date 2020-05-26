---
layout: post
title: Extending Kubernetes - Create Controllers for Core and Custom Resources
categories: [Blog]
tags: [kubernetes]
---

Kubernetes is powerful and ships with a lot of out-of-the-box functionality. But as we start to think of new ways to use Kubernetes, we may want to have the ability to create our very own “Kubernetes logic” inside of our cluster. This is where the ability to create controllers and custom resources can help: It allows us to extend Kubernetes.

## What is this?

* This post can be broken down into sub-topics:
* Controllers overview
* Controller event flow
* Controller with core resources
* Controller with custom resources
* Defining custom resources
* Generating custom resource code
* Wiring up the generated code to the controller
* Creating Custom Resource Definitions
* Running the controller

## What is this NOT?

This post is not a discussion about when you should use custom resources (and controllers). This assumes that you are looking for the knowledge on how to create them, whether out of curiosity or a requirement.

For a really good summary of when you should or shouldn’t create custom resources and controllers, please refer to the [official Kubernetes documentation on the topic](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#should-i-add-a-custom-resource-to-my-kubernetes-cluster).

## Controllers overview

Kubernetes has a very “pluggable” way to add your own logic in the form of a controller. A controller is a component that you can develop and run in the context of a Kubernetes cluster.

Controllers are an essential part of Kubernetes. They are the “brains” behind the resources themselves. For instance, a Deployment resource for Kubernetes is tasked with making sure there is a certain amount of pods running. This logic can be found in the [deployment controller (GitHub)](https://github.com/kubernetes/kubernetes/blob/master/pkg/controller/deployment/deployment_controller.go).

You can have a custom controller without a custom resource (e.g. custom logic on native resource types). Conversely, you can have custom resources without a controller, but that is a glorified data store with no custom logic behind it.

## Controller event flow

Working backwards (as far as event flow goes), the controller “subscribes” to a queue. The controller worker is going to block on a call to get the next item from the queue.

> An event is the combination of an action (create, update, or delete) and a resource key (typically in the format of namespace/name).

Before we talk about how the queue is populated for the controller, it is worth mentioning the idea of an informer. The informer is the “link” to the part of Kubernetes that is tasked with handing out these events, as well as retrieving the resources in the cluster to focus on. Put another way, **the informer is the proxy between Kubernetes and your controller (and the queue is the store for it)**.

Part of the informer’s responsibility is to register event handlers for the three different types of events: Add, update, and delete. It is in those informer’s event handler functions that we add the key to the queue to pass off logic to the controller’s handlers.

See below for an illustration of the event flow...

![image1](/images/k8s-custom-1.png)

## Controller: Core resources

There are two types of resources that controllers can "watch": Core resources and custom resources. Core resources are what Kubernetes ship with (for instance: Pods).

To work with core resources, when you define your informer you specify a few components...

* ListWatch — the ListFunc and WatchFunc should be referencing native APIs to list and watch core resources
* Controller handlers — the controller should take into account the type of resource that it expects to work with

In the case of the example, [this informer (GitHub)](https://github.com/trstringer/k8s-controller-core-resource/blob/master/main.go#L52-L59) is defined to list and watch pods...

```go
// get the Kubernetes client for connectivity
client := getKubernetesClient()

// create the informer so that we can not only list resources
// but also watch them for all pods in the default namespace
informer := cache.NewSharedIndexInformer(
    // the ListWatch contains two different functions that our
    // informer requires: ListFunc to take care of listing and watching
    // the resources we want to handle
    &cache.ListWatch{
        ListFunc: func(options meta_v1.ListOptions) (runtime.Object, error) {
            // list all of the pods (core resource) in the deafult namespace
            return client.CoreV1().Pods(meta_v1.NamespaceDefault).List(options)
        },
        WatchFunc: func(options meta_v1.ListOptions) (watch.Interface, error) {
            // watch all of the pods (core resource) in the default namespace
            return client.CoreV1().Pods(meta_v1.NamespaceDefault).Watch(options)
        },
    },
    &api_v1.Pod{}, // the target type (Pod)
    0,             // no resync (period of 0)
    cache.Indexers{},
)
```

This could just as easily been programmed to work with deployments, daemon sets, or any other core resource that ships with Kubernetes.

For a more detailed look into how a controller for core resources would work, please refer [to the GitHub repo showing an example of this](https://github.com/trstringer/k8s-controller-core-resource). A few things to note, I specifically wrote this code to be read as easily as possible. This includes everything in a single package, as well as extremely verbosely commented code. So hopefully it reads like a book! The significant source code files are...

* main.go — this is the entry point for the controller as well as where everything is wired up. Start here
* controller.go — the Controller struct and methods, and where all of the work is done as far as the controller loop is concerned
* handler.go — the sample handler that the controller uses to take action on triggered events

## Controller: Custom resources

Handling core resource events is interesting, and a great way to understand the basic mechanisms of controllers, informers, and queues. But the use-cases are limited. The real power and flexibility with controllers is when you can start working with custom resources.

You can think of custom resources as the data, and controllers as the logic behind the data. Working together, they are a significant component to extending Kubernetes.

The base components of our controller will remain mostly the same as when working with core resources: We will still have an informer, a queue, and the controller itself. But now we need to define the actual custom resource and inject that into the informer.

## Define custom resource

When developing a custom resource (and controller) you will undoubtedly already a requirement. The first step in defining the custom resource is to figure out the following...

* The API group name — in my case I’ll use trstringer.com but this can be whatever you want
* The version — I’ll use “v1” for this custom resource but you are welcome to use any that you like. For some ideas of existing API versions in your existing Kubernetes cluster you can run kubectl api-versions. Some common ones are “v1”, “v1beta2”, “v2alpha1”
* Resource name — how your resource will be individually identified. For my example I’ll use the resource name MyResource

Before we create the resource and necessary items, let’s first create the directory structure: `$ mkdir -p pkg/apis/myresource/v1`.

Create the group name const in a new file: `$ touch pkg/apis/myresource/register.go`...

```go
package myresource

const GroupName = "trstringer.com"
```

Our new package has the same name as the resource and defines the group name for future reference.

Create the resource structs: `$ touch pkg/apis/myresource/v1/types.go`...

```go
package v1

import (
    meta_v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +genclient
// +genclient:noStatus
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// MyResource describes a MyResource resource
type MyResource struct {
    // TypeMeta is the metadata for the resource, like kind and apiversion
    meta_v1.TypeMeta `json:",inline"`
    // ObjectMeta contains the metadata for the particular object, including
    // things like...
    //  - name
    //  - namespace
    //  - self link
    //  - labels
    //  - ... etc ...
    meta_v1.ObjectMeta `json:"metadata,omitempty"`

    // Spec is the custom resource spec
    Spec MyResourceSpec `json:"spec"`
}

// MyResourceSpec is the spec for a MyResource resource
type MyResourceSpec struct {
    // Message and SomeValue are example custom spec fields
    //
    // this is where you would put your custom resource data
    Message   string `json:"message"`
    SomeValue *int32 `json:"someValue"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// MyResourceList is a list of MyResource resources
type MyResourceList struct {
    meta_v1.TypeMeta `json:",inline"`
    meta_v1.ListMeta `json:"metadata"`

    Items []MyResource `json:"items"`
}
```

For all intents and purposes, this is the data structure of our custom resource. We include Kubernetes resource components like metadata, but this is our skeleton resource that we expect to use.

Hopefully the comments explain most things here, but you’ll also see a few comments in the format of `// +<tag_name>[=value]`. These are "indicators" for the code generator (usage of the generator is explained with a walk-through below) that direct specific behavior for code generation...

* **+genclient** — generate a client (see below) for this package
* **+genclient:noStatus** — when generating the client, there is no status stored for the package
* **+k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object** — generate deepcopy logic (required) implementing the runtime.Object interface (this is for both MyResource and MyResourceList)

Create a doc source file for the package: `$ touch pkg/apis/myresource/v1/doc.go`...

```go
// +k8s:deepcopy-gen=package
// +groupName=trstringer.com

package v1
```

Like in types.go, we have a couple of comment tags for the code generator. When defined in doc.go for the package, these settings take effect for the whole package. Here we set deepcopy should be generated for all types in the package (unless otherwise turned off). And we tell the generator what the API group name is with the +groupName tag.

The client requires a particular API surface area for custom types, and the package needs to include AddToScheme and Resource. These functions handle adding types to the schemes. Create the source file for this functionality in the package: `$ touch pkg/apis/myresource/v1/register.go`...

```go
package v1

import (
    meta_v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/runtime/schema"

    "github.com/trstringer/k8s-controller-core-resource/pkg/apis/myresource"
)

// GroupVersion is the identifier for the API which includes
// the name of the group and the version of the API
var SchemeGroupVersion = schema.GroupVersion{
    Group:   myresource.GroupName,
    Version: "v1",
}

// create a SchemeBuilder which uses functions to add types to
// the scheme
var AddToScheme = runtime.NewSchemeBuilder(addKnownTypes).AddToScheme

func Resource(resource string) schema.GroupResource {
    return SchemeGroupVersion.WithResource(resource).GroupResource()
}

// addKnownTypes adds our types to the API scheme by registering
// MyResource and MyResourceList
func addKnownTypes(scheme *runtime.Scheme) error {
    scheme.AddKnownTypes(
        SchemeGroupVersion,
        &MyResource{},
        &MyResourceList{},
    )

    // register the type in the scheme
    meta_v1.AddToGroupVersion(scheme, SchemeGroupVersion)
    return nil
}
```

At this point we should have all of the boilerplate to run the code generator to do a lot of the heavy lifting to create the client, informer, and lister code (as well as the deepcopy functionality that is required).

## Run the code generator

There is a little bit of setup to run the code generator. I’ve included the shell commands below that you need to run. It’s the k8s.io/code-generator package that contains the generate-groups.sh shell script which we will use to do all of the heavy lifting (this shell script directly invokes the client-gen, informer-gen, and lister-gen bins).

```
# ROOT_PACKAGE :: the package (relative to $GOPATH/src) that is the target for code generation
ROOT_PACKAGE="github.com/trstringer/k8s-controller-core-resource"
# CUSTOM_RESOURCE_NAME :: the name of the custom resource that we're generating client code for
CUSTOM_RESOURCE_NAME="myresource"
# CUSTOM_RESOURCE_VERSION :: the version of the resource
CUSTOM_RESOURCE_VERSION="v1"

# retrieve the code-generator scripts and bins
go get -u k8s.io/code-generator/...
cd $GOPATH/src/k8s.io/code-generator

# run the code-generator entrypoint script
./generate-groups.sh all "$ROOT_PACKAGE/pkg/client" "$ROOT_PACKAGE/pkg/apis" "$CUSTOM_RESOURCE_NAME:$CUSTOM_RESOURCE_VERSION"

# view the newly generated files
tree $GOPATH/src/$ROOT_PACKAGE/pkg/client
# pkg/client/
# ├── clientset
# │   └── versioned
# │       ├── clientset.go
# │       ├── doc.go
# │       ├── fake
# │       │   ├── clientset_generated.go
# │       │   ├── doc.go
# │       │   └── register.go
# │       ├── scheme
# │       │   ├── doc.go
# │       │   └── register.go
# │       └── typed
# │           └── myresource
# │               └── v1
# │                   ├── doc.go
# │                   ├── fake
# │                   │   ├── doc.go
# │                   │   ├── fake_myresource_client.go
# │                   │   └── fake_myresource.go
# │                   ├── generated_expansion.go
# │                   ├── myresource_client.go
# │                   └── myresource.go
# ├── informers
# │   └── externalversions
# │       ├── factory.go
# │       ├── generic.go
# │       ├── internalinterfaces
# │       │   └── factory_interfaces.go
# │       └── myresource
# │           ├── interface.go
# │           └── v1
# │               ├── interface.go
# │               └── myresource.go
# └── listers
#     └── myresource
#         └── v1
#             ├── expansion_generated.go
#             └── myresource.go
# 
# 16 directories, 22 files
```

After running the code generator we now have generated code that handles a large array of functionality for our new resource. Now we need to tie a lot of loose ends together for our new resource.

## Wire up the generated code

There are a couple of changes we need to make. First, in our helper function that gets the Kubernetes client, we need to now also return a an instance of a configured client that can interact with MyResource resources...

```go
// retrieve the Kubernetes cluster client from outside of the cluster
func getKubernetesClient() (kubernetes.Interface, myresourceclientset.Interface) {
    // construct the path to resolve to `~/.kube/config`
    kubeConfigPath := os.Getenv("HOME") + "/.kube/config"

    // create the config from the path
    config, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
    if err != nil {
        log.Fatalf("getClusterConfig: %v", err)
    }

    // generate the client based off of the config
    client, err := kubernetes.NewForConfig(config)
    if err != nil {
        log.Fatalf("getClusterConfig: %v", err)
    }

    myresourceClient, err := myresourceclientset.NewForConfig(config)
    if err != nil {
        log.Fatalf("getClusterConfig: %v", err)
    }

    log.Info("Successfully constructed k8s client")
    return client, myresourceClient
}
```

We also need to now store the custom resource client, and we can utilize the generated helper function to return an informer tailored to the custom resource...

```go
func main() {
    // get the Kubernetes client for connectivity
    client, myresourceClient := getKubernetesClient()

    // retrieve our custom resource informer which was generated from
    // the code generator and pass it the custom resource client, specifying
    // we should be looking through all namespaces for listing and watching
    informer := myresourceinformer_v1.NewMyResourceInformer(
        myresourceClient,
        meta_v1.NamespaceAll,
        0,
        cache.Indexers{},
    )

    // ... remainder of main.main unchanged and omitted for brevity
}
```

## Custom Resource Definition

Now that we’ve created the custom logic part of the custom resource (through the controller), we need to actually create the data part of our custom resource: the Custom Resource Definition.

I put my CRD in a separate dir at the root of the repo: `$ mkdir crd`. And then I create my definition: `$ touch crd/myresource.yaml`...

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: myresources.trstringer.com
spec:
  group: trstringer.com
  version: v1
  names:
    kind: MyResource
    plural: myresources
  scope: Namespaced
```

This should appear straightforward, as we’re using this CRD to define the API group, version, and name of the custom resource.

Create the CRD in your cluster by running `$ kubectl apply -f crd/myresource.yaml`.

The full code for this example can be found on [this repo (GitHub)](https://github.com/trstringer/k8s-controller-custom-resource).

## Running the controller
To run the controller, in the root of the repo run `$ go run *.go`. And then in a separate shell, create an object that is of type MyResource. I did this by creating an example configuration in my root repo: `$ mkdir example && touch example/example-myresource.yaml`...

```yaml
apiVersion: trstringer.com/v1
kind: MyResource
metadata:
  name: example-myresource
spec:
  message: hello world
  someValue: 13
```

And then I created this in my cluster: `$ kubectl apply -f example/example-myresource.yaml` and the output from my controller logging shows that my custom controller did indeed pick up this create event for this resource (and could have handled it however it needed to be handled)...

![image2](/images/k8s-custom-2.png)

## Summary

Kubernetes is an exciting platform, and one of the really great features of it is the ability to extend it. The sky is the limit, and hopefully with this additional knowledge it’ll be easier to understand how controllers work and how to create your own.

Enjoy!

## References

* https://kubernetes.io/docs/concepts/api-extension/custom-resources/ (official Kubernetes documentation on custom resources)
* https://github.com/kubernetes/sample-controller (example controller)
* https://github.com/kubernetes/code-generator (code-generator source repo)
* https://blog.openshift.com/kubernetes-deep-dive-code-generation-customresources/ (great description from the OpenShift blog on how to use the code-generator and explanation of the tagging system `<client|informer|lister>-gen` expects)
* https://engineering.bitnami.com/articles/kubewatch-an-example-of-kubernetes-custom-controller.html (overview and implementation of core resource watching controller from Bitnami)
* https://github.com/trstringer/k8s-controller-core-resource (sample of custom controller with a core resource)
* https://github.com/trstringer/k8s-controller-custom-resource (sample of custom controller with a custom resource)
