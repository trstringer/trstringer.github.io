---
layout: post
title: Observability with OpenTelemetry Part 3 - SDK and Exporting
categories: [Blog]
tags: [devops,kubernetes,opentelemetry]
---

* [Part 1 - Introduction](https://trstringer.com/otel-part1-intro/)
* [Part 2 - Instrumentation](https://trstringer.com/otel-part2-instrumentation/)
* **Part 3 - Exporting**
* [Part 4 - Collector](https://trstringer.com/otel-part4-collector/)
* [Part 5 - Propagation](https://trstringer.com/otel-part5-propagation/)
* [Part 6 - Ecosystem](https://trstringer.com/otel-part6-ecosystem/)
* [Sample OTel microservices application: trstringer/otel-shopping-cart](https://github.com/trstringer/otel-shopping-cart)

In the last blog post, I talked about how you collect telemetry with OpenTelemetry using your language-specific API. This included both manual and automatic instrumentation. And this is great!... But collecting telemetry is only part of the solution. You need to route this telemetry somewhere, and add some metadata to it as well. This is where the SDKs come into play.

## Tracer provider

One of the key tenants of the SDK is the tracer provider. The tracer provider is what connects the telemetry gathered from the API with the rest of the world. In Go, `TracerProvider` is an interface with a single method `Tracer`, with the following signature:

```go
Tracer(instrumentationName string, opts ...TracerOption) Tracer
```

This `Tracer` method returns an object that implements the `Tracer` interface, with also has a single method `Start`, which we've been using in instrumentation:

```go
Start(ctx context.Context, spanName string, opts ...SpanStartOption) (context.Context, Span)
```

It's the tracer provider that we are utilizing when we make our calls to create the span:

```go
import "go.opentelemetry.io/otel"

// ...

ctx, span := otel.Tracer(telemetry.TelemetryLibrary).Start(ctx, "get_product_price")
```

`otel.Tracer` does a lookup for the global tracer provider to get the `Tracer` to then start. So as you can see, it's the tracer provider that provides us this link. But before you can use the tracer provider, you need to set one up.

*Note: I mentioned above, and in a previous blog post, the idea of a "global" tracer provider. Utilizing the global tracer provider is an easier way to handle this, as the API does a lookup when we call `otel.Tracer` for the global tracer provider. In the event this doesn't satisfy your requirements, though, you are free to pass around the tracer provider to consumers so that it can be referenced directly instead of looked up globally.*

## Resource

Some of the metadata that the tracer provider handles is the resource. This is a description of your process or service that is generating the telemetry data. Think about it like the metadata that describes the service itself. Here's the resource object created for my cart service:

```go
import (
    "go.opentelemetry.io/otel/sdk/resource"
    semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

// ...

res, err := resource.New(
    ctx,
    resource.WithAttributes(
        semconv.ServiceNameKey.String("cart"),
        semconv.ServiceVersionKey.String("v1.0.0"),
    ),
)
```

One of the key parts of the service resource is the attributes that are added. OpenTelemetry has defined a set of standards for resource attribute keys and values and you can find them documented in [OTel's Resource Semantic Conventions documentation](https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/). For instance, you typically want to define at least the service name and version information, as you can see in that example. But there is *much* more that you can specify, which is dependent on the resource itself. Is it run in the cloud? Semantic conventions defines different attributes for different cloud providers. Running it in Kubernetes? There are SemConv guidelines that [cover a resource in Kubernetes](https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/k8s/).

For my service, when traces are captured the spans will now have this resource data:

```
Resource labels:
     -> service.name: STRING(cart)
     -> service.version: STRING(v1.0.0)
```

## Exporter

Now that we have created the resource object, we need to define a destination for the telemetry data. This can be a large array of exporters, but in my case I'm going to use the OpenTelemetry Collector (more on that in the next blog post), and this can have an HTTP or gRPC connection. I opt to use gRPC and setup the connection and the OTLP exporter:

```go
import (
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "google.golang.org/grpc"
)

// ...

hostIP := os.Getenv("HOST_IP")
if hostIP == "" {
    return nil, fmt.Errorf("unexpected no host IP address for receiver")
}
receiverAddress := fmt.Sprintf("%s:%d", hostIP, 4317)

conn, err := grpc.DialContext(
    ctx,
    receiverAddress,
    grpc.WithTransportCredentials(insecure.NewCredentials()),
    grpc.WithBlock(),
)
if err != nil {
    return nil, fmt.Errorf("error creating client connection to collector: %w", err)
}

otlpTraceExporter, err := otlptracegrpc.New(
    ctx,
    otlptracegrpc.WithGRPCConn(conn),
)
```

*Note: In my case because this is a demo application, I'm using an insecure connection to the collector but in production you should be using a proper form of authentication for your connections.*

As a word on exporters, there are a large variety that are available to you, such as: Console output (to view from stdout), Jaeger (to send data directly there), Prometheus, and others as well. The benefit of using an OTLP exporter and sending data to the OTel Collector is that you can fork the data, process it, and have a lot more control (as we'll see in the next post). Because of this flexibility, this example will just use the OTLP exporter and we can work with the telemetry data in the Collector however we want (outputing to stdout, sending to Jaeger, etc.). *Much more on this in the next post!*

## Tying it all together

Now that we have the resource (**what** is generating the telemetry data) and the exporter (**where** the telemetry data is going), we put them together to form the tracer provider:

```go
tp := trace.NewTracerProvider(
    trace.WithSampler(trace.AlwaysSample()),
    trace.WithResource(res),
    trace.WithSpanProcessor(trace.NewBatchSpanProcessor(otlpTraceExporter)),
)
```

When the tracer provider is created, we need to set it as the global tracer provider:

```go
import (
    "go.opentelemetry.io/otel"
)

// ...

otel.SetTracerProvider(tp)
```

Next we need to set up propagation. In a follow-up blog post I'm going to be talking about propagation and baggage in depth, but for now just know that propagation is how we use OTel traces across multiple services and processes. It's what puts the "distributed" in "distributed tracing".

```go
import (
    "go.opentelemetry.io/otel/propagation"
)

// ...

otel.SetTextMapPropagator(
    propagation.NewCompositeTextMapPropagator(
        propagation.TraceContext{},
        propagation.Baggage{}),
)
```

Finally, we need to call `TracerProvider.Shutdown` to cleanup and close the span processors (in our case, we're using the batch span processor which will send completed spans to the exporter):

```go
defer func() {
    if err := tp.Shutdown(context.Background()); err != nil {
        fmt.Printf("Error shutting down tracer provider: %v", err)
        os.Exit(1)
    }
}()
```

*Note: We don't just run `defer tp.Shutdown(context.Background())` because we need to do some level of error handling.*

## Python tracer provider

Most of my services are written in Go, but I did write a service (the price service) in Python. For the sake of completeness, here's how to create and set a similar tracer provider in Python:

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

resource = Resource(attributes={
    SERVICE_NAME: "price",
    SERVICE_VERSION: "v1.0.0"
})
tracer_provider = TracerProvider(resource=resource)

host_ip = os.environ.get("HOST_IP")
if host_ip is None:
    print("Must pass in environment var HOST_IP")
    sys.exit(1)

tracer_provider.add_span_processor(span_processor=BatchSpanProcessor(
    OTLPSpanExporter(endpoint=f"{host_ip}:4317", insecure=True)
))
trace.set_tracer_provider(tracer_provider)
```

The implementation of the resource, span processor, and setting the global tracer provider are the same as the Go description.

## Summary

This is great! Now we've taken the telemetry data generated by the API and shipped it outside of the observed process to an exporter and added some metadata to it (the resource)! Next we will look at how we can handle this data with the OpenTelemetry Collector.
