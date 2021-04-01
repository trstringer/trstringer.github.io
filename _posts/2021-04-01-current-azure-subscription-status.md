---
layout: post
title: Show the Current Azure CLI Subscription in the Terminal
categories: [Blog]
tags: [azure]
---

I live in the terminal for almost everything, and that includes managing my Azure resources with the Azure CLI. Like a lot of others working with Azure, there are a handful of subscriptions that I deal with. I have one that I primarily use for work, but I also have my personal subscription.

Like others that deal with multiple subscriptions, before I do something or start the day I typically run `az account show` to see what my current subscription is. But I got a little tired of that and I started to want to have that information always in my terminal.

I'm also [tmux](https://github.com/tmux/tmux/wiki) user, and one of the features of tmux is the bottom status bar. For me, this is the perfect place to display what my current Azure subscription is. I wrote a quick shell script:

**current_subscription.sh**

```bash
#!/bin/bash

ACCOUNT_INFO=$(az account show 2> /dev/null)
if [[ $? -ne 0 ]]; then
    echo "no subscription"
    exit
fi

SUB_ID=$(echo "$ACCOUNT_INFO" | jq ".id" -r)
SUB_NAME=$(echo "$ACCOUNT_INFO" | jq ".name" -r)
USER_NAME=$(echo "$ACCOUNT_INFO" | jq ".user.name" -r)

STATUS_LINE="$USER_NAME @"

if [[ "$SUB_ID" == "MY_PERSONAL_SUBSCRIPTION_ID" ]]; then
    STATUS_LINE="$STATUS_LINE 🏠"
elif [[ "$SUB_ID" == "MY_WORK_SUBSCRIPTION_ID" ]]; then
    STATUS_LINE="$STATUS_LINE 🏢"
else
    STATUS_LINE="$STATUS_LINE $SUB_NAME"
fi

echo "$STATUS_LINE"
```

In my case, I put this in my tmux config but you could also put this script's output in any other mechanism that takes string output (such as your PS1 prompt setting).

Here's the final result. When I'm in my personal subscription, I see this:

![Personal subscription status](../images/az-subscription-statusline1.png)

Now I always know which Azure subscription my CLI is logged into! No more guessing!
