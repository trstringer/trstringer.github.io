---
layout: post
title: Search for a Key Vault Certificate in an Azure Subscription
categories: [Blog]
tags: [azure,openssl,security]
---

If you are working with Azure Key Vault certificates, you might have a hard time locating the certificate itself in your Azure subscription. Let's take a scenario:

*You notice that the certificate of your website is getting close to expiration. You want to analyze the certificate in your Azure subscription but you can't remember where the certificate is (which vault or which certificate resource).*

One way you can locate the certificate is by getting the certificate fingerprint:

```
$ openssl s_client -connect <site_url>:443 < /dev/null 2> /dev/null |
    openssl x509 -fingerprint -noout |
    awk -F "=" '{print $2}' | tr -d ":"
EF047A02FD11B7D4BBE1B357C2982C036BAB0AF0
```

I chose to get the certificate by using `openssl s_client`, but if you already had the certificate you could omit this part and just call `openssl x509` directly. Then I pass this through `awk` to parse out "SHA1 Fingerprint=" prefix, and then finally use `tr` to delete the colons in the fingerprint.

Now with the fingerprint I can search through all of my Azure Key Vaults in my subscription and filter by `x509ThumbprintHex`:

```
$ az resource list \
        --resource-type "Microsoft.KeyVault/vaults" \
        --query "[].name" -o tsv |
    xargs -rn 1 az keyvault certificate list \
        --query "[?x509ThumbprintHex == 'EF047A02FD11B7D4BBE1B357C2982C036BAB0AF0'].id" \
        -o tsv --vault-name
https://mykeyvault.vault.azure.net/certificates/mycert
```

This will list all Azure Key Vaults and for each of them it will list all certificates that match the fingerprint. As long as the certificate does, in fact, live in a Key Vault that you have access to, you should get a response in the format: `https://<key_vault_name>.vault.azure.net/certificates/<certificate_name>`.

Now you can work with this certificate as needed:

```
$ az keyvault certificate show \
    --vault-name mykeyvault \
    --name mycert
```

Hopefully this post has shown how you can search for a certificate in an Azure subscription!
