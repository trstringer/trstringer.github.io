---
layout: post
title: Get Azure Key Vault Certificate Expiration Dates
categories: [Blog]
tags: [azure,security,openssl]
---

Certificates expiring can (and often do) cause unexpected outages. It's one of the few times when "nothing changed" can cause a serious issue. Azure Key Vault is a great cloud service that can help create and maintain certificates. A common question for your Key Vault certificates might be *"when will my certificates expire?"* Maybe that's for running a report, or kicking off some automation script.

At any rate, it is common to want to know how long until your certificates expire. Here's a quick shell script (with a little embedded Python to make datetime math a little easier) to get the expiration date (and how many days until then) of your Key Vault certificates:

```bash
#!/bin/bash

KEYVAULTS=$(az keyvault list --query "[].name" -o tsv)
# KEYVAULTS="<space_delimited_list_of_vault_names>"

for KEYVAULT in $KEYVAULTS; do
    for CERT in $(az keyvault certificate list \
            --vault-name "$KEYVAULT" \
            --query "[].name" -o tsv); do
        EXPIRES=$(az keyvault certificate show \
            --vault-name "$KEYVAULT" \
            --name "$CERT" \
            --query "attributes.expires" -o tsv)
        PYCMD=$(cat <<EOF
from datetime import datetime
from dateutil import parser
from dateutil.tz import tzutc
expire_days = (parser.parse('$EXPIRES') - datetime.utcnow().replace(tzinfo=tzutc())).days
if expire_days > 0:
    msg = "in {} days".format(expire_days)
else:
    msg = "already expired!!!"
print(msg)
EOF
        )
        EXPIRES_DELTA=$(python3 -c "$PYCMD")
        echo "$CERT (Vault: $KEYVAULT) expires on $EXPIRES ($EXPIRES_DELTA)"
    done
done
```

Line 3 of the script retrives *all* Key Vaults in a subscription, but you can instead use line 4 and just pass in a space-delimited list of Key Vaults to look through. The output could be similar to the following:

```
$ ./key_vault_expiration_dates.sh
cert1 (Vault: kv1) expires on 2021-04-06T01:27:05+00:00 (in 63 days)
cert2 (Vault: kv2) expires on 2021-04-26T13:04:38+00:00 (in 84 days)
cert3 (Vault: kv2) expires on 2021-01-13T06:27:08+00:00 (already expired!!!)
```

Hopefully this script can help you quickly pull some very valuable information!
