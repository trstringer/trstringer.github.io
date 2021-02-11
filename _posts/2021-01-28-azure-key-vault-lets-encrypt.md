---
layout: post
title: Azure Key Vault Certificates with Let's Encrypt as the Issuer CA
categories: [Blog]
tags: [azure,security,openssl]
---

Azure Key Vault is a great product for managing data protection, and one of the main features is the ability to handle TLS/SSL certificates. The way Azure Key Vault works with certificates is that it handles the signing process through two partnered providers (at the writing of this blog post): DigiCert and GlobalSign.

With a partnered provider you have the capability to tell a Key Vault to create a certificate for you. And then voila, you'll have your X.509 certificate. You can download the certificate and/or the PKCS#12 bundle to serve your TLS/SSL needs.

That's great, and really easy!

...But what if you want to use a different, non-partnered Certificate Authority? I really like [Let's Encrypt](https://letsencrypt.org/). In short, Let's Encrypt is an amazing thing for computing: It provides free certificates and an easy(ier) path to secure network communication.

## Non-partnered issuer CA overview

When working with any non-partnered CA in Key Vault it is up to you, the implementer, to handle some of the things that are automatically handled with Key Vault and a partnered CA (like DigiCert), namely the certificate signing and creation step.

Here are the logical steps you need to take in this scenario:

1. Create the *certificate request* in your Azure Key Vault
1. Take the certificate signing request (CSR) from the pending certificate request
1. Submit this CSR to your preferred CA (in this blog post, Let's Encrypt)
1. Take the resulting full chain X.509 certificate that your CA gives you and merge it back into the Key Vault certificate request

## Create the Key Vault

Before we start working with Key Vault certificates, we need to have an existing Key Vault in place:

```
$ az group create --location eastus --name kv1
$ az keyvault create --resource-group kv1 --name kv1
```

## Create the Key Vault certificate request

The first step is to create the certificate request itself. If this was done outside of Key Vault manually with OpenSSL it would typically be an `openssl x509 genrsa` command, followed up with an `openssl req` to generate the CSR. But because we want Azure to handle this, we'll make a REST API call to create the certificate request:

```
$ az rest \
    --method post \
    --url "https://kv1.vault.azure.net/certificates/cert1/create?api-version=7.1" \
    --body @~/dev/tls/cert_policy2.json \
    --resource "https://vault.azure.net"
```

*Note: the reason I'm using `az rest` instead of `az keyvault certificate create` is that I couldn't get the latter to work with my certificate policy.*

The certificate policy that I passed into the body of the REST API request is:

```json
{
    "policy": {
        "x509_props": {
          "subject": "CN=trstringer.com"
        },
        "issuer": {
          "name": "Unknown"
        }
    }
}
```

The subject is just the Common Name set to the domain name that I want this certificate registered for, and the issuer is set to "Unknown" for a non-partnered CA.

## Retrieve the CSR

Now that we've created the certificate request, we need to retrieve the actual CSR that we need to send to the CA. This can be done with a few commands:

```
$ bash -c \
    'echo "-----BEGIN CERTIFICATE REQUEST-----" &&
    az keyvault certificate pending show \
        --vault-name kv1 \
        --name cert1 \
        --query csr -o tsv &&
    echo "-----END CERTIFICATE REQUEST-----"' > ./cert1.csr
```

If you want to analyze the CSR before sending it to the CA, you can do this:

```
$ openssl req -in ./cert1.csr -noout -text
```

## Send the CSR to the CA

This is heavily dependent on what issuer CA you are using. Here is how this works with Let's Encrypt, though. Utilizing [certbot](https://certbot.eff.org/), I did the following:

```
$ sudo certbot certonly \
    --preferred-challenges dns \
    --manual \
    --csr ./cert1.csr
```

Just to note, I didn't want certbot to do any installation, and this was on my local machine (for testing) so I had to do a manual verification. On top of that, for me it was easiest to do a DNS challenge. Here is response I got:

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Performing the following challenges:
dns-01 challenge for trstringer.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.trstringer.com with the following value:

<some_unique_value>

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```

The `<some_unique_value>` is a placeholder for a string that certbot is using to verify that I own this domain name. With a DNS challenge, you have to go to your domain name DNS settings and create a TXT record that is named `_acme-challenge` and has the value of `<some_unique_value>`.

Once you complete this with your domain name registrar, it usually takes a few minutes for this to take effect. *You have to wait until it does with certbot!* The best way to know *when* it has taken effect is to run:

```
$ dig -t txt _acme-challenge.<your_domain_name>
```

When this works, you'll see the answer section with the following:

```
;; ANSWER SECTION:
_acme-challenge.<your_domain_name> 3600 IN TXT   "<some_unique_value>"
```

At that point you can continue with certbot for the registration. This should then successfully complete and give you three files: the certificate, the chain, and the full chain (which is the certificate + chain).

## Merge the certificate to Key Vault

Now that we have received our certificate from our preferred CA, we need to complete this by merging it back into the Key Vault certificate request:

```
$ az keyvault certificate pending merge \
    --name cert1 \
    --vault-name kv1 \
    --file ./fullchain.pem
```

And that's it! Now Key Vault has your complete certificate for use.

## Using your certificate

Now that we have our certificate in Key Vault, there are a few ways to consume it. Below are a few operations you can do.

### Download the certificate

```
$ az keyvault certificate download \
    --vault-name kv1 \
    --name cert1 \
    --file ./cert1.crt
```

You can analyze the contents with OpenSSL:

```
$ openssl x509 -in ./cert1.crt -noout -text
```

### Download the PKCS#12 bundle

A PKCS#12 archive includes both the private key (which is a sensitive component of public-key cryptography) and the full chain certificate. Because of this, it should be treated securely.

```
$ az keyvault secret download \
    --name cert1 \
    --vault-name kv1 \
    --file ./cert1.pfx \
    --encoding base64
```

Analyze the contents of the archive:

```
$ openssl pkcs12 -in ./cert1.pfx -nodes -passin pass:
```

*Note: by passing in `-nodes` you are stating that you don't want the private key encrypted. If that isn't the case, then omit `-nodes`.*

Extract the certificates from the PKCS#12 bundle:

```
$ openssl pkcs12 \
    -in ./cert1.pfx \
    -nokeys \
    -out ./cert1_fullchain.crt \
    -passin pass:
```

Extract the private key from the PKCS#12 bundle:

```
$ openssl pkcs12 \
    -in ./cert1.pfx \
    -nodes \
    -nocerts \
    -out ./cert1.key \
    -passin pass:
```

Again, strongly noting that by passing in `-nodes` you are opting out of encrypting the private key. And to also reiterate, the private key should be protected and secured.

## Summary

Hopefully this blog post has illustrated how you can take advantage of the great things that Azure Key Vault offers with certificates, but by also utilizing you preferred CA that isn't partnered with Key Vault (in this case, Let's Encrypt). Enjoy!
