---
layout: post
title: Kubernetes API Groups, Resources, and Verbs
categories: [Blog]
tags: [kubernetes]
---

I recently talked about [how to setup RBAC](https://trstringer.com/kubectl-from-within-pod/) for a particular scenario. One of the key features of RBAC are roles. Here is what that particular role looked like...

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

There are a few things here that might be confusing at first glance. The straightforward part is probably the `resources` list. Typically you know *what* you want to specify permissions on. In this case, `pods`. But what about `apiGroups`? Why is it an empty list? I know *what* I want the permissions to be, but how do you know what `verbs` are valid?

There is a single command that will give you all of these answers...

```bash
$ kubectl api-resources -o wide
```

Here is some sample output from this command (it's quite verbose unedited)...

*You might have to scroll to the right to see all of the output.*

```
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND                             VERBS
namespaces                        ns                                          false        Namespace                        [create delete get list patch update watch]
nodes                             no                                          false        Node                             [create delete deletecollection get list patch update watch]
persistentvolumeclaims            pvc                                         true         PersistentVolumeClaim            [create delete deletecollection get list patch update watch]
persistentvolumes                 pv                                          false        PersistentVolume                 [create delete deletecollection get list patch update watch]
pods                              po                                          true         Pod                              [create delete deletecollection get list patch update watch]
services                          svc                                         true         Service                          [create delete get list patch update watch]
deployments                       deploy       apps                           true         Deployment                       [create delete deletecollection get list patch update watch]
replicasets                       rs           apps                           true         ReplicaSet                       [create delete deletecollection get list patch update watch]
statefulsets                      sts          apps                           true         StatefulSet                      [create delete deletecollection get list patch update watch]
jobs                                           batch                          true         Job                              [create delete deletecollection get list patch update watch]
```

The `NAME` is the resource that you want to apply permissions to. `APIGROUP` corresponds to the `apiGroups` role specification. This tells you what group the resource belongs to. Note that `pods` (and many other resources) have an empty `APIGROUP`. This is because they are part of the core API group.

By specifying wide output (`-o wide`) we get some helpful information about `VERBS`. These are all of the supported verbs for the resource and what you specify in `verbs`.

*Bonus: `SHORTNAMES` are really helpful aliases when interacting with resources from `kubectl`. They save a lot of keystrokes!*

Now a quick exercise. Let's say you want to create a role for creating and deleting deployments. You know that your resource name is `deployments`. Let's do some discovery on the rest of the specs...

```bash
$ kubectl api-resources -o wide | grep -E "^deployments"
```

The output should look similar to the following...

```bash
deployments                       deploy       apps                           true         Deployment                       [create delete deletecollection get list patch update watch]
```

So now we know that `apiGroups` should include the `apps` API group. And the verbs we are looking for are `create` and `delete`. So our `PolicyRule` array should resemble the following...

```yaml
rules:
  apiGroups:
    - apps
  resources:
    - deployments
  verbs:
    - create
    - delete 
```

I hope this has helped clarify role specificcations for RBAC!
