---
layout: post
title: Azure Linux VM SSH Error - Permission denied (publickey)
categories: [Blog]
tags: [azure, linux]
---

When you are working with Linux VMs (IaaS) in Azure, the most common way to access the VM is through Secure Shell (SSH). A common issue when you're trying to SSH into your Linux VM for the first time is this error:

> user@machine.region.cloudapp.azure.com: Permission denied (publickey).

In this blog post, I'm going to step through how to troubleshoot a likely cause of this and how to fix it.

## Which key goes where?

When you create an SSH key pair with `ssh-keygen`, it creates a key **pair**. Sometimes it can be confusing when to pass in your public key (.pub) or your private key (no extension). Here's an easy way to remember this, as far as Azure Linux VMs are concerned:

- **Public key** - should be specified in the `--ssh-key-values` parameter when running `az vm create`. E.g. `az vm create ... --ssh-key-values ~/.ssh/my_azure_vm.pub`.
- **Private key** - should be specified when you `ssh` into the machine. E.g. `ssh -i ~/.ssh/my_azure_vm user@machine` (notice no extension on the key).

## What SSH is the VM expecting?

A quick way to find out what SSH key the VM is expecting is to show some info about the VM:

```
$ az vm show \
    --resource-group <resource_group> \
    --name <vm_name> \
    --query osProfile.linuxConfiguration.ssh.publicKeys[0].keyData \
    -o tsv
```

Compare that to the SSH **public** key that you _think_ you are using to SSH with (more on how to explicitly specify this).

## Specifying the SSH public key for access

In the above section, you were able to discover which SSH **public** key the VM is expecting. Now you need to specify the **private** key for the identity when you SSH into that machine.

When you SSH into a machine, you can either specify the identity file (the private key) that should be used with the `-i` parameter, or with SSH configuration. Refer to the above section (Which key goes where?)[#which-key-goes-where] to see an example of passing the identity file when you `ssh` into the VM.

As mentioned, you can also use SSH configuration (`/.ssh/config`) to set the identity file for a host (or hosts):

```
Host <host_spec>
  IdentityFile ~/.ssh/my_azure_vm
```

`host_spec` is either a DNS name, IP address, or a wildcard for specifying multiple hosts. For more information on `host_spec`, see `man 5 ssh_config`.

## Still can't get in? Reset your SSH key

Hopefully with the above troubleshooting you were able to figure out the correct SSH key to use, but in the event that SSH key pair is no longer available you can reset your SSH key:

```
$ az vm user update \
    --resource-group <resource_group> \
    --name <vm_name> \
    --username <your_username> \
    --ssh-key-value ~/.ssh/new_key.pub
```

Where `--ssh-key-value` is set to the location of the new SSH **public** key.

## Still can't get in with SSH? Login through Serial Console

In the event you are having other issues getting access through SSH, you can try logging in through Serial Console. To do this, you need to have a username/password combination. If you created your VM with no admin password (which is what I do), you will have to do a reset password:

```
$ az vm user update \
    --resource-group <resource_group> \
    --name <vm_name> \
    --username <your_username> \
    --password <new_password
```

And then you can navigate to the Azure Portal to login through Serial Console and troubleshoot SSH connectivity there.

## Recommendation - Use non-default keys!

Unfortunately, it is all too common to reuse an SSH key pair for many purposes. In many demos or examples, you'll typically see `~/.ssh/id_rsa` being thrown around. It's an easy default but it is recommended for security purposes to create separate SSH key pairs to use for separate requirements (in this case, Azure Linux VM access).

Here's what you should be doing:

1. Run `ssh-keygen` to generate a new SSH key pair.
1. Use the public key from the new key pair when you create your VMs.
1. Use the private key from the new key pair when you access your VMs.

## Summary

It can be frustrating to create an Azure Linux VM and then immediately try to SSH into it, only to get a publickey error. Hopefully the above information can provide a little help in troubleshooting this error!
