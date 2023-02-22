---
layout: post
title: List Prometheus Scraping Targets
categories: [Blog]
tags: [kubernetes,devops,prometheus]
---

When working with Prometheus, oftentimes you're dealing with dynamic targets. The most common example of that is [Kubernetes targets](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) with the `kubernetes_sd_config` configuration. Even if your Prometheus configuration is valid and doesn't have errors, you might be wandering why a particular target's metrics aren't being scraped.

One of the ways to see *exactly* what Prometheus is scraping is to make a direct HTTP request to the Prometheus API. In my case, my instance of Prometheus is running directly inside my Kubernetes cluster, so I to start a port forwarding session first:

```bash
$ kubectl port-forward -n <prometheus_namespace> <prometheus_pod> 9090:9090
```

Now I can query the targets from Prometheus like this:

```bash
$ curl localhost:9090/api/v1/targets
```

*Note: I like to pipe this output through `jq` for nicer viewing.*

```json
{
  "status": "success",
  "data": {
    "activeTargets": [
      {
        "discoveredLabels": {
          "__meta_kubernetes_endpoints_name": "istiod",
          "__meta_kubernetes_namespace": "istio-system",
        },
        "labels": {},
        "scrapePool": "istiod",
        "scrapeUrl": "http://10.244.1.10:15012/metrics",
        "globalUrl": "http://10.244.1.10:15012/metrics",
        "lastError": "Get \"http://10.244.1.10:15012/metrics\": EOF",
        "lastScrape": "2023-02-19T17:29:04.418635073Z",
        "lastScrapeDuration": 0.002133704,
        "health": "down",
        "scrapeInterval": "30s",
        "scrapeTimeout": "10s"
      },
      {
        "discoveredLabels": {
          "__meta_kubernetes_endpoints_name": "istiod",
          "__meta_kubernetes_namespace": "istio-system",
        },
        "labels": {},
        "scrapePool": "istiod",
        "scrapeUrl": "http://10.244.1.10:15014/metrics",
        "globalUrl": "http://10.244.1.10:15014/metrics",
        "lastError": "",
        "lastScrape": "2023-02-19T17:29:02.045086304Z",
        "lastScrapeDuration": 0.003880408,
        "health": "up",
        "scrapeInterval": "30s",
        "scrapeTimeout": "10s"
      }
    ],
    "droppedTargets": []
  }
}
```

There's a lot of really great information here. First off, you'll see the `activeTargets`, which will be all the targets that Prometheus is trying to scrape. For each of the targets, some notable fields are:

* `health` - Shows either "up" or "down", depending on if Prometheus was able to successfully scrape the URL.
* `lastError` - This is helpful if you have an endpoint that is "down". This will be the last error.
* `discoveredLabels` - I truncated the output, but this will have all of the labels that were found on the target resource.
* `scrapeUrl` - The URL that Prometheus is trying to scrape. If you have a "down" target, but you expect it to be returning metrics then this will be helpful in manual troubleshooting.

After the `activeTargets`, there is a list of `droppedTargets`. For each dropped target you'll have the `discoveredLabels` and part of that is the `job` that the target was originally part of (prior to being dropped).

Hopefully this has helped show how you can quickly see what targets Prometheus is trying to get metrics from!
