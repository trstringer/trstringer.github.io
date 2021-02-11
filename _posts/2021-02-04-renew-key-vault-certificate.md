---
layout: post
title: Renew Azure Key Vault Certificates from Let's Encrypt
categories: [Blog]
tags: [azure,security,openssl]
---

In a recent blog post, I wrote about how to create [Azure Key Vault Certificates with Let's Encrypt as the Issuer CA](https://trstringer.com/azure-key-vault-lets-encrypt/). This is a great start to utilizing a non-partnered Certificate Authority to issue your Azure Key Vault certificates... but we can't stop there. *Certificates are not forever!* They will expire.

This blog post will show you how to manually renew your certificates in Azure Key Vault that were issued from a non-partnered CA, like Let's Encrypt.

**Note: In an upcoming blog post, I'll show how to automate this process so that it requires no manual intervention.**

## Versions

Certificate renewal in Key Vault is done by creating a new version of the certificate. You can list out the current versions:

```
$ az keyvault certificate list-versions \
    --vault-name kv1 \
    --name cert1
```

If you haven't renewed your certificate yet, there will be just a single version (the original) of the certificate.

## Create a new version

Because we aren't using a partnered CA, the whole renewal process is not automatic. We need to do a few steps to renew the certificate, and the first is to create a new version. This is an identical call to creating the certificate (reference the previous blog post for specifics):

```
$ az rest \
    --method post \
    --url "https://kv1.vault.azure.net/certificates/cert1/create?api-version=7.1" \
    --body @~/dev/tls/cert_policy.json \
    --resource "https://vault.azure.net"
```

## Retrieve the CSR

Once we create a new version of the certificate, the behavior will be similar from the original creation. The new version will be a pending certificate waiting on a merge. So we have to retrieve the certificate signing request (CSR) from Key Vault so that we can submit it to the CA:

```
$ bash -c \
    'echo "-----BEGIN CERTIFICATE REQUEST-----" &&
    az keyvault certificate pending show \
        --vault-name kv1 \
        --name cert1 \
        --query csr -o tsv &&
    echo "-----END CERTIFICATE REQUEST-----"' > ./cert1_renew.csr
```

This will construct the proper CSR and dump it to the file `cert1_renew.csr`.

## Submit the CSR to the CA

Now that we have the CSR, it's time to submit this to the CA. In my case with Let's Encrypt, I'll do this through certbot:

```
$ sudo certbot certonly \
    --preferred-challenges dns \
    --manual \
    --csr ./cert1_renew.csr \
    --fullchain-path ./fullchain.pem
```

The result will be the full chain certificate in `fullchain.pem`. You can validate the new expiration date of the local certificate:

```
$ openssl x509 -in ./fullchain.pem -noout -dates
notBefore=Feb  2 22:13:05 2021 GMT
notAfter=May  3 22:13:05 2021 GMT
```

## Merge the certificate to Key Vault

Finally we need to merge that certificate back to Key Vault to complete the renewal process, which is the creation of a new version:

```
$ az keyvault certificate pending merge \
    --vault-name kv1 \
    --name cert1 \
    --file ./fullchain.pem
```

As long as that was successful, that should complete the renewal of the certificate! You can validate this by listing out the version of the certificate:

```
$ az keyvault certificate list-versions \
    --vault-name kv1 \
    --name cert1
```

That should now show the new version of the certificate. And to take it a step further, you could show the effective expiration date of the certificate directly from Key Vault:

```
$ az keyvault certificate download \
    --vault-name kv1 \
    --name cert6 \
    --file /dev/stdout | openssl x509 -noout -dates
```

This will display the `notBefore` (start date) and the `notAfter` (expiration date) of the certificate.

## Use the certificate

Now that the certificate is renewed and stored in Key Vault, don't forget to pull this down for your usage!

## Summary

This blog post has showed the manual steps on how to renew a non-partnered CA issued certificate. In the next blog post I'll show how to do this automatically!
