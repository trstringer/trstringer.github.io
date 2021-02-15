---
layout: post
title: Nginx Error - key values mismatch
categories: [Blog]
tags: [security,devops,openssl]
---

The following error message may be thrown when trying to start nginx:

> nginx: [emerg] SSL_CTX_use_PrivateKey_file("/etc/ssl/private/cert1.key") failed (SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch)

The root cause of this error message is that your private key and your certificate do not match when trying to enable SSL in your nginx instance. To verify the private and public key nginx will compare the modulus of each. If they don't match, you will get this error.

The key and certificate that are being compared can be found in your site's nginx server configuration:

* The private key is defined as `ssl_certificate_key`
* The certificate is defined as `ssl_certificate`

Verify the **modulus of your private key** (passing it through `md5sum` to create a smaller string to visually compare):

```
$ sudo openssl rsa -modulus -in /etc/ssl/private/cert1.key -noout | md5sum
5c9f7e379e9e28adf61ece609d32c878  -
```

And **compare that with the modulus from the certificate**:

```
$ sudo openssl x509 -modulus -in /etc/ssl/certs/cert1_wrong.crt -noout | md5sum
fed25082bfadf88e0e505fd5e92602fb  -
```

As you can see in my case, the digests are different. What can cause this different modulus? Namely that it could be a certificate that was generated from a different key. But also, if you have extracted the certificate from a PKCS#12 bundle, you might have to change the order of certificates in the certificate extracted from the bundle, as the modulus will be calculated from the first certificate found in the file. When extracting the certificate, you can first extract just the client certificate with `-clcerts` and the concatenate that with the CA certs with `-cacerts` subsequently to create a full chain certificate with the right order of certificates.

Once you have resolved the mismatched certificate, you should be able to validate the matching moduli before successfully starting nginx:

```
$ sudo openssl x509 -modulus -in /etc/ssl/certs/cert1_fixed.crt -noout | md5sum
5c9f7e379e9e28adf61ece609d32c878  -
```

Hopefully this can help you quickly resolve this nginx SSL issue!
