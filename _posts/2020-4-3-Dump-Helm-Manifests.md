---
layout: post
title: Dump Manifests for all Revisions for a Helm Release
categories: [Blog]
tags: [kubernetes, helm, devops]
---

Being able to diagnose what changed in a Helm chart is an important requirement. One of the tools that we can use to see what exactly Helm is deploying to our Kubernetes cluster is by running `helm get manifest`. You can pass in the revision to see what historical manifests looked like (a good way to see exactly what has changed). But this can be a tedious and laborious task, so I wrote a quick shell script to pull all of the manifests for the entire history of a release.

```bash
#!/bin/bash

NAMESPACE="$1"
RELEASE="$2"
TMP_DIR=$(mktemp -d)

if [[ -z "$NAMESPACE" || -z "$RELEASE" ]]; then
    echo "Missing parameters"
    echo "./helm-manifest-dump.sh <namespace> <release>"
    exit 1
fi

for REVISION in $(helm history -n "$NAMESPACE" "$RELEASE" | tail -n +2 | awk '{print $1}'); do
    helm get manifest \
		-n "$NAMESPACE" \
        --revision "$REVISION" \
        "$RELEASE" > "$TMP_DIR/${RELEASE}_${REVISION}"
done

echo "Manifests located in '$TMP_DIR'"
```

Just run `./helm-manifest-dump.sh <namespace> <release>`. This dumps all manifests to the temporary output directory, allowing you to `grep`, `cat`, `diff`, or do whatever you want to analyze them.

This small script can be found on [GitHub](https://github.com/trstringer/helm-manifest-dump).

Enjoy!
