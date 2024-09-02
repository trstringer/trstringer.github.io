---
layout: post
title: Configuring and Using an External Disk in Linux
categories: [Blog]
tags: [linux]
---

This is one of those things that I do so much but always need to think. So I'm going to create some documentation for myself, and maybe it'll help others. Specifically, I'm going to setup an external disk with encryption.

## Setup

First, plug in your disk to your Linux machine. Find out which disk it is. In my case, it's `sda`. If you need to partition the disk then run `sudo fdisk /dev/sda` (if your disk is `sda`, or whatever else it might be) and then create a new partition with `n`.

I am using Debian, so to encrypt the disk I use LUKS:

```
sudo cryptsetup luksFormat /dev/sda1
```

I enter a complex passphrase (and save it in my password manager). Then I unlock the partition:

```
sudo cryptsetup luksOpen /dev/sda1 backup-disk
```

I like to zero out a disk before using it:

```
sudo dd if=/dev/zero of=/dev/mapper/backup-disk status=progress bs=16M
```

Note: This can take a long time. For example, on a 4 TB disk it can take about 12 hours on typical hardware.

Format the partition:

```
sudo mkfs.ext4 /dev/mapper/backup-disk
```

Create the mountpoint:

```
sudo mkdir /backup-disk
sudo chown trstringer:trstringer /backup-disk
```

In my case, I use `/backup-disk` as my mountpoint dir and change the ownership to my current user.

Now I can close the encrypted disk to reopen it below with the normal workflow:

```
sudo cryptsetup luksClose backup-disk
```

## Usage

First unlock the disk:

```
sudo cryptsetup luksOpen /dev/sda1 backup-disk
```

Mount the disk and navigate to it:

```
sudo mount /dev/mapper/backup-disk /backup-disk
cd /backup-disk
```

When done with the disk unmount, close the encryption, and power off the drive:

```
sudo umount /dev/mapper/backup-disk
sudo cryptsetup luksClose backup-disk
udisksctl power-off -b /dev/sda
```
