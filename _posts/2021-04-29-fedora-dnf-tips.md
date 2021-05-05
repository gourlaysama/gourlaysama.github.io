---
layout: post
title: Going further with DNF in Fedora
category: tech
tags: Fedora
date: 2021-04-29 15:39 +0200
---
Fedora's DNF package manager is easy to use for everyday tasks, but it's also easy to miss
some very useful lesser known features.
<!--more-->
This article will look at how to accomplish more with the typical DNF commands you already use.

## Running without the network

DNF regularly connects to the network to refresh metadata{% sidenote 1 'The default in Fedora
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
install a package with this, since the cache normally never contains packages waiting to be
installed.

## Fedora's archive repository

The normal Fedora repositories only keep two versions of the same package: the latest (in the `updates`
repository), and the first one for the current version of Fedora (in the `fedora` repository). This
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

### Downgrading a package

As a result, downgrading a package in Fedora, while theoretically easy, can cause surprises.
For example, trying to downgrade `systemd` will go all the way down seven (minor) versions, to the
version from the Fedora 33 release:

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

### Using the archive repository

**Edit** (5 May 2021): The repository is now enabled by default when installed; the section
was changed to reflect this.
{: .info}

Fortunately Fedora includes a repository that contains all packages that ever reached the
`updates` repository. After installing it, and setting it as disabled by default:{% sidenote 2 'since [this update][bodhi-repo-update] all versions of Fedora (except rawhide) have it enabled by default. The rational is that it is normally only installed on editions that actually need it (like [Fedora Silverblue][silverblue]).' %}

```sh
sudo dnf install fedora-repos-archive
sudo dnf config-manager --set-disabled updates-archive
```

It becomes available for use, and contains everything you might expect:

```sh
dnf list --showduplicates --enablerepo=updates-archive systemd.x86_64
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

### Undoing history

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
querying it is significantly slower than other repositories{% sidenote 3 'Because it has a lot
more metadata than normal: it only ever keeps growing in size, while the `updates` repository is
cleaned of old packages to keep it fast.' %}. If you don't mind the metadata download times, you
can remove the `--enable-repo` arguments above after enabling the repository
with:

```sh
sudo dnf config-manager --set-enabled updates-archive
```

### Locking a package in place

Keeping a downgraded package around can be annoying if DNF tries to upgrade it back again all
the time.

However, there is a [DNF command for this](https://dnf-plugins-core.readthedocs.io/en/latest/versionlock.html),
though you might have to install it first:

{% marginnote mm-lock 'Yes, this can be used to locate and install DNF commands, see below.' %}
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

You can for example use it to lock a package to minor updates:

```sh
sudo dnf -C versionlock add --raw 'firefox-88.*'
```

Or on the contrary exclude minor updates and wait for the next major one:

```sh
sudo dnf -C versionlock exclude --raw 'firefox-88.*'
```

This can be used to include or exclude packages in a more precise way, compared to adding
`exclude` entries in the DNF configuration.

## Paths instead of package names

Several DNF commands support using paths on the file-system instead of a package name.
The obvious example is `provide`, which displays packages that provide the file at that path:

```sh
dnf provides /etc/vimrc
```
{: .console}

```none
Last metadata expiration check: 1:55:07 ago on Mon 26 Apr 2021 10:19:03 AM CEST.
vim-common-2:8.2.1770-1.fc33.x86_64 : The common files needed by any version of the VIM editor
Repo        : fedora
Matched from:
Filename    : /etc/vimrc

vim-common-2:8.2.2787-1.fc33.x86_64 : The common files needed by any version of the VIM editor
Repo        : updates
Matched from:
Filename    : /etc/vimrc
```
{: .larger}

As a special convenience, `dnf provide` will prefix{% sidenote 4 'this only works with `provide`!' %}
 the search term with `/usr/bin/` if there is no match (and then `/usr/sbin`), so the
following will work:

```sh
dnf provides bzcat
```

But the path doesn't actually have to exist locally at all. For example, when installing a
package:

{% marginnote mm-dnf-path 'Note that it needs to be an *absolute* path here, otherwise you should use a wildcard.' %}
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

{% marginnote mm-reinstall-config 'Note that this will not work for most configuration files in
`/etc` since packages are usually instructed to leave local configuration changes alone.' %}
```sh
sudo dnf reinstall '/usr/share/themes/*'
sudo dnf reinstall '/boot/*'
```


## Rich dependencies

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

When manually compiling programs, build systems often use  `pkgconfig` to locate
dependencies. The same dependency names can be used with DNF, regardless of the
actual name of the package:

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

Packaged fonts can be installed by name:

```sh
sudo dnf install font(firasans)
# or all the fira fonts:
sudo dnf install font(fira*)
```

Thus you can list all fonts packaged in Fedora with:

```sh
dnf provides 'font(*)' | grep Provide | sort -u
```

### DNF commands

You sometimes see DNF commands that are not available on a system by default—in blog
posts for example. Those can be installed by DNF with:

```sh
sudo dnf install 'dnf-command(torproxy)'
```

### Libraries from various ecosystems

It is sometimes useful to have a library installed in the standard Python/Ruby/...
environment provided by Fedora. The naming of packages is usually consistent enough that
you can guess where to find something, but you can also use the following:

```sh
sudo dnf install 'rubygem(bundler)'
sudo dnf install 'perl(Socket)'
sudo dnf install 'python3dist(httplib2)'
sudo dnf install 'ocaml(Rope)'
```

### MIME handlers

DNF can be used to find applications capable of opening a file, using its `mime-type`:

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

These are just some of DNF's less used features that can help managing your system.
Hopefully this has been useful to make your life on the command line easier.

For a more complete tour of DNF see the [DNF documentation][dnf] and the [Core DNF Plugins Documentation][dnfplugins].

[dnf]: https://dnf.readthedocs.io/en/latest/
[dnfplugins]: https://dnf-plugins-core.readthedocs.io/en/latest/index.html
[bodhi-repo-update]: https://bodhi.fedoraproject.org/updates/FEDORA-2021-6348d6bf2c
[silverblue]: https://fedoramagazine.org/what-is-silverblue/