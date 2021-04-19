---
layout: post
title:  "Dnf tips and tricks in Fedora"
# date:   2020-04-16 17:04:01
category: tech
tags: fedora dnf tips
---
<!--more-->

Run only with local cache:

```sh
dnf -C list installed 'gtk*'
```
{: .console}

```none
Installed Packages
gtk-update-icon-cache.x86_64      3.24.28-2.fc33        @updates
gtk-vnc2.x86_64                   1.0.0-3.fc33          @fedora
gtk2.x86_64                       2.24.33-1.fc33        @updates
gtk3.x86_64                       3.24.28-2.fc33        @updates
gtk3-devel.x86_64                 3.24.28-2.fc33        @updates
gtkmm30.x86_64                    3.24.4-1.fc33         @updates
gtksourceview3.x86_64             3.24.11-4.fc33        @fedora
gtksourceview4.x86_64             4.8.1-1.fc33          @updates
gtkspell3.x86_64                  3.0.10-6.fc33         @fedora
```
{: .larger}

```sh
dnf provides /usr/sbin/ip
```
{: .console}

```none
Last metadata expiration check: 5:42:44 ago on Sun 18 Apr 2021 05:05:52 PM CEST.
iproute-5.8.0-1.fc33.x86_64 : Advanced IP routing and network device configuration tools
Repo        : fedora
Matched from:
Filename    : /usr/sbin/ip

iproute-5.9.0-1.fc33.x86_64 : Advanced IP routing and network device configuration tools
Repo        : updates
Matched from:
Filename    : /usr/sbin/ip
```
{: .larger}

```sh
sudo dnf install /usr/bin/gvim
dnf provides /usr/sbin/ip
dnf provides libguile*


dnf repoquery -l libwebp

sudo dnf install 'pkgconfig(gstreamer-1.0)'
# python3dist(lib_name)
# ruby(ncurses)
# font(firasans)
sudo dnf install 'dnf-command(version-lock)'

dnf provides '*/libbz2.so*'

sudo dnf reinstall /etc/systemd/sleep.conf
sudo dnf reinstall '/usr/share/themes/*'

dnf history gnome-shell
sudo dnf history undo 642 --assumeno --enablerepo=updates-archive
# dnf history /usr/bin/vim
dnf history undo <id>
```
