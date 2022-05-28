---
layout: post
title: Making GitHub API Requests with a JWT
categories: [Blog]
tags: [devops,github]
---

When working with the GitHub API, there are many operations that require a JSON web token (JWT). Just recently I wanted to find out which GitHub accounts (users and organizations) have installed a GitHub App that I published. Looking at the GitHub REST API documentation, I can see the path for [listing installations for a GitHub App](https://docs.github.com/en/rest/apps/apps#list-installations-for-the-authenticated-app).

`curl` works fine, but the [GitHub CLI](https://cli.github.com/) makes these types of things much easier. I see in the documentation that to list the installations for the app it is this `gh api` command:

```
gh api \
  -H "Accept: application/vnd.github.v3+json" \
  /app/installations
```

To make a successful request, though, you will need to generate and pass a JWT. If you didn't, you would see this helpful message:

```
$ gh api \
>   -H "Accept: application/vnd.github.v3+json" \
>   /app/installations
{
gh: A JSON web token could not be decoded (HTTP 401)
  "message": "A JSON web token could not be decoded",
  "documentation_url": "https://docs.github.com/rest"
}
```

To create this JWT, we need some information:

* The GitHub App ID, which will be the issuer claim ("iss")
* The private key that was originally generated when the App was created

*Note: The private key is sensitive data and should be kept in appropriate storage for secrets. In my case, I store this in Azure Key Vault and do not persist it anywhere else.*

More information on the authentication workflow for GitHub Apps can be found on my previous blog post: [Understanding GitHub App Authentication](https://trstringer.com/github-app-authentication/).

So for me to make this `gh api` request to get the App installations, I need to generate a JWT. I couldn't find a good utility to do this, so I created [jwt-creator](https://github.com/trstringer/jwt-creator). This utility takes a private key file as well as standard claims and generates a JWT that can be passed to GitHub.

```
$ JWT=$(az keyvault secret show \
        --vault-name <key_vault_name> \
        --name <secret_name> \
        --query value -o tsv |
    jwt-creator \
        --private-key-file - \
        --issuer <app_id> \
        --issued-at-now \
        --expires-in-seconds 300)
```

This command pulls the private key from my Azure Key Vault and then passes that into `jwt-creator` and uses the App ID as the issuer. The result JWT is stored in a variable that can now be passed to `gh api`:

```
$ gh api \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer $JWT" \
    /app/installations
```

This request succeeds and now I'm able to see all of the accounts that have installed this GitHub App!
