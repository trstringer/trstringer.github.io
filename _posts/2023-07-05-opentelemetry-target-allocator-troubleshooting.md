---
layout: post
title: Troubleshooting the OpenTelemetry Target Allocator
categories: [Blog]
tags: [devops,opentelemetry,prometheus,kubernetes]
---

In a recent blog post I talked about how OpenTelemetry uses the [target allocator](https://github.com/open-telemetry/opentelemetry-operator/tree/main/cmd/otel-allocator) to generate Prometheus config to know what targets to scrape. But... what happens when it doesn't seem to be working? In this blog post I'm going to step through some troubleshooting steps that I have used to figure out what's going wrong.

## List jobs

The first step is to see what jobs your target allocator is looking at. We can do this by `curl`ing the `/jobs` endpoint.

First I will port forward from my local machine to be able to curl the target allocator endpoint:

```
$ kubectl port-forward svc/otelcol-targetallocator 8080:80
```

Now we can get the jobs:

```
$ curl localhost:8080/jobs | jq
```

My output is the following:

```json
{
  "serviceMonitor/default/my-app/0": {
    "_link": "/jobs/serviceMonitor%2Fdefault%2Fmy-app%2F0/targets"
  },
  "otel-collector": {
    "_link": "/jobs/otel-collector/targets"
  }
}
```

## List job targets

Now that we can validate our jobs, let's see what they are targeting. One of the helpful things is to just append the `_link` onto the root target allocator URL. So for me to get the targets I would just curl this:

```
$ curl localhost:8080/jobs/serviceMonitor%2Fdefault%2Fmy-app%2F0/targets | jq
```

Here you'll want to search for target you expected. In my case, `app: my-app` from my `ServiceMonitor` is in this list:

```json
{
  "otelcol-collector-0": {
    "_link": "/jobs/serviceMonitor%2Fdefault%2Fmy-app%2F0/targets?collector_id=otelcol-collector-0",
    "targets": [
      ...
      {
        "targets": [
          "10.244.0.6:10250"
        ],
        "labels": {
          "__meta_kubernetes_pod_labelpresent_chart": "true",
          "__meta_kubernetes_pod_container_image": "quay.io/prometheus-operator/prometheus-operator:v0.65.2",
          "__meta_kubernetes_endpointslice_port_protocol": "TCP",
          "__meta_kubernetes_service_label_release": "prometheus",
          ...
          "__meta_kubernetes_pod_labelpresent_app_kubernetes_io_instance": "true"
        }
      },
      ...
    ]
  }
}
```

This will tell us that the pod we care about is in the list of targets for this job.

## Show the scrape config

The thing we _really_ care about is what scrape config the target allocator is delivering to the collectors. We can do this by curling the `/scrape_configs` endpoint:

```
$ curl localhost:8080/scrape_configs
```

```json
{
  ...
  "serviceMonitor/default/my-app/0": {
    "enable_http2": true,
    "follow_redirects": true,
    "honor_timestamps": true,
    "job_name": "serviceMonitor/default/my-app/0",
    "kubernetes_sd_configs": [
      {
        "enable_http2": true,
        "follow_redirects": true,
        "kubeconfig_file": "",
        "namespaces": {
          "names": [
            "default"
          ],
          "own_namespace": false
        },
        "role": "endpointslice"
      }
    ],
    "metrics_path": "/metrics",
    "relabel_configs": [
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "job"
        ],
        "target_label": "__tmp_prometheus_job_name"
      },
      {
        "action": "keep",
        "regex": "(my-app);true",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_service_label_app",
          "__meta_kubernetes_service_labelpresent_app"
        ]
      },
      {
        "action": "keep",
        "regex": "prom",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_endpointslice_port_name"
        ]
      },
      {
        "action": "replace",
        "regex": "Node;(.*)",
        "replacement": "${1}",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_endpointslice_address_target_kind",
          "__meta_kubernetes_endpointslice_address_target_name"
        ],
        "target_label": "node"
      },
      {
        "action": "replace",
        "regex": "Pod;(.*)",
        "replacement": "${1}",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_endpointslice_address_target_kind",
          "__meta_kubernetes_endpointslice_address_target_name"
        ],
        "target_label": "pod"
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_namespace"
        ],
        "target_label": "namespace"
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_service_name"
        ],
        "target_label": "service"
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_pod_name"
        ],
        "target_label": "pod"
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_pod_container_name"
        ],
        "target_label": "container"
      },
      {
        "action": "drop",
        "regex": "(Failed|Succeeded)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_pod_phase"
        ]
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "${1}",
        "separator": ";",
        "source_labels": [
          "__meta_kubernetes_service_name"
        ],
        "target_label": "job"
      },
      {
        "action": "replace",
        "regex": "(.*)",
        "replacement": "prom",
        "separator": ";",
        "target_label": "endpoint"
      },
      {
        "action": "hashmod",
        "modulus": 1,
        "regex": "(.*)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__address__"
        ],
        "target_label": "__tmp_hash"
      },
      {
        "action": "keep",
        "regex": "$(SHARD)",
        "replacement": "$1",
        "separator": ";",
        "source_labels": [
          "__tmp_hash"
        ]
      }
    ],
    "scheme": "http",
    "scrape_interval": "30s",
    "scrape_timeout": "10s"
  }
}
```

We can see the `kubernetes_sd_configs`, which would be a familiar sight if you've been dealing with Prometheus configuration before.

## Validate receiver config

One of the things that might be causing metrics to not show up in OpenTelemetry is misconfiguring the target allocator. Here is what this might look like in your `Collector`:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otelcol
spec:
  ...
  config: |
    receivers:
      prometheus:
        config:
          scrape_configs:
          - job_name: 'otel-collector'
            scrape_interval: 30s
            static_configs:
            - targets: [ '0.0.0.0:8888' ]
        target_allocator:
          endpoint: http://otelcol-targetallocator
          interval: 30s
          collector_id: "${POD_NAME}"
        ...
```

Here we can see the receiver has the `target_allocator` configured. Make sure this endpoint is correct. One way to do this is by running a ephemeral debug container on the collector pod:

```
$ kubectl debug -it --image ubuntu otelcol-collector-0
```

Inside the container I'll install `curl`:

```
# apt update && apt install -y curl
```

Then try to curl your `target_allocator.endpoint`:

```
# curl http://otelcol-targetallocator/scrape_configs
```

You _should_ receive back the JSON dump of scrape config. If that doesn't work, troubleshoot the connectivity and the endpoint.

## Custom image

In the event you need to use a custom image, you can specify this in the `targetAllocator` configuration for the `Collector` resource:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otelcol
spec:
  mode: statefulset
  targetAllocator:
    image: ghcr.io/open-telemetry/opentelemetry-operator/target-allocator:main
    enabled: true
    serviceAccount: otelcol
    prometheusCR:
      enabled: true
      serviceMonitorSelector:
        app: my-app
  config: |
    ...
```
Some custom images you might configure here is a newer (or older) version of the target allocator, or your custom build. If you need to patch the target allocator, this is the way to have the collector deploy your custom image.

## Summary

Hopefully this blog post has shown as few ways that you can troubleshoot the target allocator if you don't have Prometheus metrics flowing into OpenTelemetry!
