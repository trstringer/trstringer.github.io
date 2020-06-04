---
layout: post
title: Running and Debugging Azure Functions Locally on Linux
categories: [Blog]
tags: [azure, azure-functions, linux]
---

Today started out with some [awesome Azure Functions news that Linux and Mac are now supported for running and debugging locally](https://azure.microsoft.com/en-us/blog/serverless-for-all-developers-bringing-azure-functions-to-linux-mac-planet-scale-nosql-real-time-analytics-and-productivity-apps/). As an avid Linux user and huge proponent of Azure Functions (and all things serverless, for that matter!), the timing was great. I needed to do a little work on [Sherlock](https://github.com/trstringer/sherlock) (an integration testing sandbox environment provisioning tool for Azure, written on top of Azure Functions).

For what it's worth, I'm running Fedora 26.

## Getting Azure Functions installed and running locally

I followed [this great guide from Donna how to set it up](https://blogs.msdn.microsoft.com/appserviceteam/2017/09/25/develop-azure-functions-on-any-platform/) and get rolling with a sample HTTP triggered Azure Function App. For the most part, this went well but there were a few extra things I had to do.

For the initial installation, I tried to run `npm install -g azure-functions-core@core` as root, but I kept getting `Error: EACCESS: permission denied, mkdir '/root/.azurefunctions`. Seeing the Mac instructions to add on `--unsafe-perm` to the `npm install` I gave that a shot and that seemed to install it correctly.

I then needed to [install .NET Core for Fedora](https://www.microsoft.com/net/core#linuxfedora).

For what it's worth, because I ran the npm install as root it appears as though I need to run all of my `func` commands as root.

Then I stepped through the sample in Donna's post to create the JavaScript HttpTrigger sample. It worked! I then kicked it off with `sudo func host start`. I was greeted by familiar (from the Portal) and comforting feedback in my terminal:

![Azure Functions running locally](/images/azure-functions-linux-1.png)

I ran a quick curl on the URL that was displayed: `curl http://localhost:7071/api/HttpTriggerJavaScript?name=world` and I was greeted with a pleasing Hello world. It's working! But that's only half the battle. Time to set and hit a breakpoint locally.

I chose to use Chrome to debug my node.js Azure Function (Donna showed how to use VS Code in her post, so if you are a VS Code user reference that. My preferred editor is Vim, so instead of using a different editor I chose to use Chrome for the debugging piece). In Chrome, I navigated to `chrome://inspect` and selected `Configure...`. I then added `localhost:5858` to the remote targets (as described in the blog post as well as displayed in the output when I ran `func host start`).

Back in `chrome://inspect`, the remote targets section was now populated with the nodejsWorker.js that Azure Functions was running. Clicking the inspect link opened up the source for the Azure Function. Almost there! I set a breakpoint and then ran the curl again. Sure enough! **Breakpoint hit... success!**

![Azure Functions running locally](/images/azure-functions-linux-2.png)

This is awesome. Glad to see that us Linux (and Mac) users can now work with Azure Functions locally!
