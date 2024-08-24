---
layout: post
title: Linux Disk Recover - initramfs Bug
categories: [Blog]
tags: [linux, debian]
---

I run Debian sid, and because I like to live on the edge of Debian sometimes things break. A similar situation happened a few weeks ago. I had updated my machine, and the next time I booted my machine I went to decrypt my drive and I was greeted with the following error (and [reported Debian bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1068848)):

```
libgcc_s.so.1 must be installed for pthread_exit to work

Aborted

cryptsetup: ERROR: nvme0n1p3_crypt: cryptsetup failed, bad password or options?
```

Yikes! I couldn't get into my machine. I couldn't decrypt my disk, and I was locked out. I needed to do two things: Access my disk and fix initramfs.

I'm going to break up this blog post into two different parts:

1. Recovering Linux with a live image
2. Fixing initramfs

The former is quite common, and the latter is unusual. But in the event I ever run into this again, I'd like to have this well-documented!

## Linux recovery with a live image

I run Debian, so this will be specific to Debian, but many distros have the same capability to run a live image. There are a handful of situations where you might have an issue getting your Linux machine booted up. Me running into a cryptsetup issue is one of many examples. But whatever happened, and you need to get into your machine without the proper boot sequence, this should help.

### Get a live image

With Debian, you can get a [live install image](https://www.debian.org/CD/live/). You can choose whatever desktop environment you want, I'm a fan of XFCE through and through, so I downloaded the Debian 12 XFCE live image ISO. Get a spare USB drive and use an image writer to write the ISO to the USB disk.

_Note: It's a great idea to have a live image disk always available. If you're anything like me, you can't predict when you'll need it. And there's a chicken and egg problem if your only machine is down, and you can't create a live disk to recover your machine._

### Boot the live disk

Boot your machine with the live disk. Do this by temporarily changing the boot device and point it to the USB that is imaged with the live disk. For Debian, it will boot into an options screen where you can select the correct option. Once you do that, you're now in the live install and you can move around as you would in any other Linux installation.

### Mount the disk

Before we can do anything with our machine's disk(s), we need to first mount them. Mine is encrypted so I need to first open it:

```
# cryptsetup luksOpen /dev/nvme0n1p3 nvme0n1p3_crypt
```

In my case, I needed to use `nvme0n1p3_crypt`, as this is what is set in my `/etc/crypttab`, and it needed to match for `update-initramfs`.

Now I can mount the disk:

```
# mkdir /media/originaldisk
# mount /dev/mapper/debian--vg-root /media/originaldisk
```

This part is important and can vary. In my case, my volume group is name `debian-vg`, but that might vary for other configs.

And now the disk is mounted and you can `cd /media/originaldisk` and do what you need to do!

## Fixing initramfs

My specific problem was that there was a bug with initramfs, so I needed to update it. When I mounted my disk, I mentioned that I needed to match what was in `/etc/crypttab`.

It's important that prior to mounting, we _might_ need to do some volume group detection and modifications. Running `vgscan --mknodes` scans all LVM block devices, and also special files in `/dev`. `vgchange -ay` activates all LVs. You shouldn't have to do this, but in the event you need to rename your volume group, you may need to run `vgchange <vg_uuid> <new_vg_name>`. Just note that this should match what is in grub config.

I _also_ need to mount the boot partition:

```
# mount /dev/nvme0n1p2 /media/originaldisk/boot
```

That partition might be different, but doing an `ls /media/originaldisk/boot` should show your initrd image and your kernel, as well as the grub config. That's a pretty good indication it's the correct one.

Now I need to mount a few others:

```
# cd /
# mount -t proc proc /media/originaldisk/proc
# mount -t sysfs sys /media/originaldisk/sys
# mount -o bind /dev /media/originaldisk/dev
```

Then `chroot` into this mounted root:

```
# chroot /media/originaldisk /bin/bash
```

I have to make sure I have `thin-provisioning-tools` installed:

```
# apt install thin-provisioning-tools
```

And finally, fix initramrfs:

```
# update-initramfs -u -k all
```

You _should_ be able to list out available kernel versions with `linux-version list`. This is what `update-initramfs` will use when specifying `all` for the version.

And that's it! I was able to boot back into my original disk and initramfs was fixed.
