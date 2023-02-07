---
layout: post
title: Troubleshooting Error 'Jwt issuer is not configured' in Istio and Envoy
categories: [Blog]
tags: [istio,kubernetes]
---

Recently I was troubleshooting the following error:

> Jwt issuer is not configured

I had created the following `RequestAuthentication` resource prior to this:

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: test-jwt
spec:
  jwtRules:
    - issuer: "https://sts.windows.net/my-tenant-id"
      jwksUri: "https://login.microsoftonline.com:443/common/discovery/v2.0/keys"
  selector:
    matchLabels:
      app: httpbin2
```

*Note: I am using Azure AD as my identity provider, and I replaced my tenant ID with the `my-tenant-id` string.*

For the sake of completion, here was my `AuthorizationPolicy`:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: test-authz
spec:
  selector:
    matchLabels:
      app: httpbin2
  rules:
    - from:
        - source:
            requestPrincipals: ["*"]
    - to:
        - operation:
            paths: ["/insecure"]
```

When I was making requests that required authorization (any route except `/insecure`) I was receiving this error:

```
$ INGRESS_IP=$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ ACCESS_TOKEN=$(az account get-access-token --query accessToken -o tsv)

$ curl -H "Authorization: Bearer $ACCESS_TOKEN" -H "host: httpbin2.com" http://${INGRESS_IP}/whatever
```

And that's when I received the error **Jwt issuer not configured**. I turned on debug logging in my Envoy sidecar and saw this:

```
2023-02-07T23:19:27.497295Z	debug	envoy jwt	extract authorizationBearer
2023-02-07T23:19:27.497330Z	debug	envoy jwt	origins-0: JWT authentication starts (allow_failed=false), tokens size=1
2023-02-07T23:19:27.497337Z	debug	envoy jwt	origins-0: startVerify: tokens size 1
2023-02-07T23:19:27.497402Z	debug	envoy jwt	origins-0: Parse Jwt eyJ0...vxlOQ
2023-02-07T23:19:27.497750Z	debug	envoy jwt	origins-0: Verifying JWT token of issuer https://sts.windows.net/my-tenant-id/
2023-02-07T23:19:27.497771Z	debug	envoy jwt	origins-0: JWT token verification completed with: Jwt issuer is not configured
2023-02-07T23:19:27.497777Z	debug	envoy jwt	Jwt authentication completed with: Jwt issuer is not configured
```

There is a small clue here, but for all intents and purposes this just mostly reiterated what I already knew: Jwt issuer is not configured. I looked in the Envoy source code and found that this error is the `JwtUnknownIssuer` error. I [found in source](https://github.com/envoyproxy/envoy/blob/998283da32de3f30c2ccc9de5ad83e6d0fa0fc77/source/extensions/filters/http/jwt_authn/authenticator.cc#L191-L196) that this error was primarily raised when the issuer was not in the existing set of allowed issuers:

```c++
  ENVOY_LOG(debug, "{}: Verifying JWT token of issuer {}", name(), jwt_->iss_);
  // Check if `iss` is allowed.
  if (!curr_token_->isIssuerAllowed(jwt_->iss_)) {
    doneWithStatus(Status::JwtUnknownIssuer);
    return;
  }
```

This was interesting, because my `RequestAuthentication` should've configured Envoy to include this issuer. So let's look at the proxy configuration:

```
$ istioctl proxy-config listener httpbin2-7fdc8bf54c-fj4q5 -o json
```

By looking through my listener config, I see that all of my listeners had the same issuer configured:

```json
{
    "name": "envoy.filters.http.jwt_authn",
    "typedConfig": {
        "@type": "type.googleapis.com/envoy.extensions.filters.http.jwt_authn.v3.JwtAuthentication",
        "providers": {
            "origins-0": {
                "issuer": "https://sts.windows.net/my-tenant-id",
                "localJwks": {
                    "inlineString": "..."
                },
                "payloadInMetadata": "https://sts.windows.net/my-tenant-id"
            }
        },
        "rules": [
            {
                "match": {
                    "prefix": "/"
                },
                "requires": {
                    "requiresAny": {
                        "requirements": [
                            {
                                "providerName": "origins-0"
                            },
                            {
                                "allowMissing": {}
                            }
                        ]
                    }
                }
            }
        ],
        "bypassCorsPreflight": true
    }
}
```

It was still not obvious to me what was wrong here, so I wanted to compare my configured issuer with the issuer in my JWT `iss` claim:

```
$ az account get-access-token --query accessToken -o tsv | awk -F . '{print $2}' | base64 -d | jq | grep iss
  "iss": "https://sts.windows.net/my-tenant-id/",
```

And that's when it became obvious to me. My `iss` claim had a trailing `/`, and my configured issuer in my proxy didn't have that. Once I fixed this in my `RequestAuthentication` resource, my JWT authentication started working!

I hope this blog post has illustrated a methodical way of troubleshooting a fairly cryptic Envoy error with JWT auth!
