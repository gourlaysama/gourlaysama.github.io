---
layout: post
title: Dnf tips and tricks in Fedora
category: tech
tags: fedora dnf tips
---
Fedora's `dnf` package manager has commands for most things, but there are several productivity
tips that can make life much easier.
<!--more-->
This article will look at how to improve a few common (and uncommon) tasks with `dnf`.

## Running without the network

`dnf` regularly connects to the network to refresh metadata{% sidenote 1 'The default in Fedora
is seven days for base repositories and six hours for update repositories. This can be changed
with the `metadata_expire` configuration option.' %}. This slows down even commands that do not
need information from a repository to work.

You can run with the `-C/--cacheonly` option to skip the network:

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

This option always uses the system cache (the cache of the `root` user), which is presumably
more up-to-date than the cache of the local user. You will however get an error if you try to
install a package with this, since the local cache normally never contains packages waiting to be
installed.

## Downgrading a package

Downgrading a package in Fedora is theoretically easy, but in practice can be a challenge.

The normal Fedora repositories only keep two versions of the same package: the latest (in the `updates`
repository), and the first one for this version of Fedora (in the `fedora` repository). This
can be seen by listing duplicates of a package:

{% bmarginnote mm-systemd-ver 'Note the only two options under `Available Packages`: `246.6-3` at the time Fedora 33 was released, and
`246.13-1`, the current version.' %}
```sh
dnf -C list --showduplicates systemd.x86_64
```
{: .console}

```none
Installed Packages
systemd.x86_64         246.13-1.fc33      @updates
Available Packages
systemd.x86_64         246.6-3.fc33       fedora
systemd.x86_64         246.13-1.fc33      updates
```

Thus trying to downgrade `systemd` will go all the way down seven (minor) versions:

```sh
sudo dnf downgrade systemd
```
{: .console}

```none
Dependencies resolved.
===============================================================================
 Package                  Architecture Version              Repository    Size
===============================================================================
Downgrading:
 systemd                  x86_64       246.6-3.fc33         fedora       4.0 M
 systemd-container        x86_64       246.6-3.fc33         fedora       498 k
 systemd-devel            x86_64       246.6-3.fc33         fedora       429 k
 systemd-libs             x86_64       246.6-3.fc33         fedora       578 k
 systemd-networkd         x86_64       246.6-3.fc33         fedora       467 k
 systemd-pam              x86_64       246.6-3.fc33         fedora       308 k
 systemd-rpm-macros       noarch       246.6-3.fc33         fedora        29 k
 systemd-udev             x86_64       246.6-3.fc33         fedora       1.5 M

Transaction Summary
===============================================================================
Downgrade  8 Packages
```
{: .larger}

That usually isn't what you want when trying to downgrade a recently updated package.

### Fedora's archive repository

Fortunately Fedora includes a repository that contains all packages that ever reached the
`updates` repository. After installing it:

```sh
sudo dnf install fedora-repos-archive
```

It becomes available for use (but disabled by default), and contains everything you might
expect:

```sh
dnf -C list --showduplicates --enablerepo=updates-archive systemd.x86_64
```
{: .console}

```none
Installed Packages
systemd.x86_64         246.13-1.fc33      @updates
Available Packages
systemd.x86_64         246.6-3.fc33       fedora
systemd.x86_64         246.7-1.fc33       updates-archive
systemd.x86_64         246.7-2.fc33       updates-archive
systemd.x86_64         246.10-1.fc33      updates-archive
systemd.x86_64         246.13-1.fc33      updates
systemd.x86_64         246.13-1.fc33      updates-archive
```
{: .larger}

{% bmarginnote mm-systemd-2 'The more recent `246.10-1` version is now available!' %}
```sh
sudo dnf downgrade --enablerepo=updates-archive systemd
```
{: .console .console-cont}

```none
Dependencies resolved.
===============================================================================
 Package                Arch       Version           Repository           Size
===============================================================================
Downgrading:
 systemd                x86_64     246.10-1.fc33     updates-archive     4.1 M
 systemd-container      x86_64     246.10-1.fc33     updates-archive     494 k
 systemd-devel          x86_64     246.10-1.fc33     updates-archive     425 k
 systemd-libs           x86_64     246.10-1.fc33     updates-archive     579 k
 systemd-networkd       x86_64     246.10-1.fc33     updates-archive     464 k
 systemd-pam            x86_64     246.10-1.fc33     updates-archive     307 k
 systemd-rpm-macros     noarch     246.10-1.fc33     updates-archive      24 k
 systemd-udev           x86_64     246.10-1.fc33     updates-archive     1.5 M

Transaction Summary
===============================================================================
Downgrade  8 Packages
```
{: .larger}

This also allows to successfully undo transactions with `dnf history undo` and `dnf history rollback`:

```sh
sudo dnf history undo last 
```
{: .console}

```none
Error: The following problems occurred while running a transaction:
  Cannot find rpm nevra "fedpkg-1.40-5.fc33.noarch".
  Cannot find rpm nevra "vim-X11-2:8.2.2637-1.fc33.x86_64".
  Cannot find rpm nevra "vim-common-2:8.2.2637-1.fc33.x86_64".
  Cannot find rpm nevra "vim-enhanced-2:8.2.2637-1.fc33.x86_64".
  Cannot find rpm nevra "vim-filesystem-2:8.2.2637-1.fc33.noarch".
  Cannot find rpm nevra "vim-minimal-2:8.2.2637-1.fc33.x86_64".
```
{: .larger}

```sh
sudo dnf history undo last --enablerepo=updates-archive
```
{: .console .console-cont}

```none
Dependencies resolved.
===============================================================================
 Package            Arch       Version               Repository           Size
===============================================================================
Downgrading:
 fedpkg             noarch     1.40-5.fc33           updates-archive      88 k
 vim-X11            x86_64     2:8.2.2637-1.fc33     updates-archive     1.9 M
 vim-common         x86_64     2:8.2.2637-1.fc33     updates-archive     6.7 M
 vim-enhanced       x86_64     2:8.2.2637-1.fc33     updates-archive     1.8 M
 vim-filesystem     noarch     2:8.2.2637-1.fc33     updates-archive      23 k
 vim-minimal        x86_64     2:8.2.2637-1.fc33     updates-archive     685 k

Transaction Summary
===============================================================================
Downgrade  6 Packages
```
{: .larger}

Note that the `updates-archive` repository should probably be kept disabled by default, because
querying it is significantly slower than other repositories{% sidenote 2 'Because it has a lot
more metadata than normal: it only ever keeps growing in size, while the `updates` repository is
cleaned of old packages to keep it fast.' %}.

### Locking a package in place

Keeping a downgraded package around can be annoying if `dnf` tries to upgrade it back again all
the time. The typical way is to add an `exclude` in the configuration, but that requires editing
configuration file.

There is a [`dnf` command for this](https://dnf-plugins-core.readthedocs.io/en/latest/versionlock.html), though you will have to install it first:

{% marginnote mm-lock 'Yes, this can be used to locate and install `dnf` commands, see below.' %}
```sh
sudo dnf install 'dnf-command(versionlock)'
```

Then it can be used to lock packages in place:

```sh
sudo dnf -C versionlock add 'vim*'
```
{: .console}

```none
Adding versionlock on: vim-minimal-2:8.2.2735-1.fc33.*
Adding versionlock on: vim-powerline-0:2.8.2-1.fc33.*
Adding versionlock on: vim-filesystem-2:8.2.2735-1.fc33.*
Adding versionlock on: vim-common-2:8.2.2735-1.fc33.*
Adding versionlock on: vim-X11-2:8.2.2735-1.fc33.*
Adding versionlock on: vim-enhanced-2:8.2.2735-1.fc33.*
```

You can also use it to lock a package to minor updates only:

```sh
sudo dnf -C versionlock add --raw 'firefox-88.*'
```

## Use filesystem paths instead of package names

Multiple `dnf` commands support using paths on the filesystem where a package name is expected.
The obvious example is `provide`, which displays packages that provide the file at that path:

```sh
dnf -C provides /usr/sbin/ip
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

But the path doesn't actually have to exist locally at all. For example, when installing a
package:

{% marginnote mm-dnf-path 'Note that it needs to be an *absolute* path, or use a wildcard (see below).' %}
```sh
sudo dnf install /usr/bin/gvim
```

Wildcards can also be used:

```sh
dnf provides '*/libbz2.so*'
```
{: .console}

```none
Last metadata expiration check: 1 day, 18:45:49 ago on Sat 17 Apr 2021 07:43:37 PM CEST.
bzip2-devel-1.0.8-4.fc33.i686 : Libraries and header files for apps which will use bzip2
Repo        : fedora
Matched from:
Filename    : /usr/lib/libbz2.so

bzip2-devel-1.0.8-4.fc33.x86_64 : Libraries and header files for apps which will use bzip2
Repo        : fedora
Matched from:
Filename    : /usr/lib64/libbz2.so

bzip2-libs-1.0.8-4.fc33.i686 : Libraries for applications using bzip2
Repo        : fedora
Matched from:
Filename    : /usr/lib/libbz2.so.1
Filename    : /usr/lib/libbz2.so.1.0.8

bzip2-libs-1.0.8-4.fc33.x86_64 : Libraries for applications using bzip2
Repo        : fedora
Matched from:
Filename    : /usr/lib64/libbz2.so.1
Filename    : /usr/lib64/libbz2.so.1.0.8
```
{: .larger}

This can be particularly useful to re-install locally modified files:

{% marginnote mm-reinstall-config 'Note that this will not work for most config files in `/etc` since packages
are usually instructed to leave local config changes alone.' %}
```sh
sudo dnf reinstall '/usr/share/themes/*'
```

## Use rich dependencies instead of package names

Packages in Fedora can provide more that file paths. They also expose richer information
about what becomes available once the package is installed.

### Missing libraries

Packages expose native library dependencies directly, so an error message like this:

```none
error while loading shared libraries: libbz2.so.1: \
  cannot open shared object file: No such file or directory
```
{: .larger}

Can be diagnosed with:

```sh
dnf provides 'libbz2.so.*'
```
{: .console}

```none
Last metadata expiration check: 2:03:46 ago on Tue Apr 20 08:19:21 2021.
bzip2-libs-1.0.8-4.fc33.i686 : Libraries for applications using bzip2
Repo        : fedora
Matched from:
Provide    : libbz2.so.1

bzip2-libs-1.0.8-4.fc33.x86_64 : Libraries for applications using bzip2
Repo        : @System
Matched from:
Provide    : libbz2.so.1()(64bit)

bzip2-libs-1.0.8-4.fc33.x86_64 : Libraries for applications using bzip2
Repo        : fedora
Matched from:
Provide    : libbz2.so.1()(64bit)
```
{: .larger}

### Build dependencies

When locally compiling programs, building systems often use  `pkgconfig` to locate build
dependencies, and the same dependency names can be used to install the right package and
all its dependencies. For example:

```sh
# before compiling a program that requires dbus
sudo dnf install 'pkgconfig(dbus-1)'
```
{: .console}

```none
Dependencies resolved.
===============================================================================
 Package                 Arch        Version                Repository    Size
===============================================================================
Installing:
 dbus-devel              x86_64      1:1.12.20-2.fc33       fedora        36 k
Installing dependencies:
 libpkgconf              x86_64      1.7.3-5.fc33           updates       36 k
 pkgconf                 x86_64      1.7.3-5.fc33           updates       41 k
 pkgconf-m4              noarch      1.7.3-5.fc33           updates       14 k
 pkgconf-pkg-config      x86_64      1.7.3-5.fc33           updates       10 k
 xml-common              noarch      0.6.3-55.fc33          fedora        31 k

Transaction Summary
===============================================================================
Install  6 Packages
```
{: .larger}

### Fonts

Packages fonts can be installed by name:

```sh
sudo dnf install font(firasans)
# or all the fira fonts:
sudo dnf install font(fira*)
```

Or to list all packaged fonts in Fedora:

```sh
dnf -C provides 'font(*)' | grep Provide | sort -u
```

### Libraries from various ecosystems

```sh
sudo dnf install 'rubygem(bundler)'
sudo dnf install 'perl(Socket)'
sudo dnf install 'python3dist(httplib2)'
sudo dnf install 'ocaml(Rope)'
```

### MIME handlers

`dnf` can be used to find applications capable of opening a file, using its `mime-type`:

```sh
# what is that unknown file?
file -b --mime-type pres.ppt
```
{: .console}

```none
application/vnd.ms-powerpoint
```

```sh
# how can I open it?
dnf provides 'mimehandler(application/vnd.ms-powerpoint)'
```
{: .console .console-cont}

```none
calligra-okular-odpgenerator-3.2.1-4.fc33.i686 : OpenDocument presenter support for okular
Repo        : fedora
Matched from:
Provide    : mimehandler(application/vnd.ms-powerpoint)

calligra-okular-odpgenerator-3.2.1-4.fc33.x86_64 : OpenDocument presenter support for okular
Repo        : fedora
Matched from:
Provide    : mimehandler(application/vnd.ms-powerpoint)

calligra-stage-3.2.1-4.fc33.x86_64 : A full-featured presentation program
Repo        : fedora
Matched from:
Provide    : mimehandler(application/vnd.ms-powerpoint)

libreoffice-impress-1:7.0.1.2-5.fc33.x86_64 : LibreOffice Presentation Application
Repo        : fedora
Matched from:
Provide    : mimehandler(application/vnd.ms-powerpoint)

libreoffice-impress-1:7.0.5.2-1.fc33.x86_64 : LibreOffice Presentation Application
Repo        : updates
Matched from:
Provide    : mimehandler(application/vnd.ms-powerpoint)
```
{: .larger}

## Wrapping up

`dnf` provides a lot of useful tools to solve more advanced problems than installing or upgrading
packages. TODO