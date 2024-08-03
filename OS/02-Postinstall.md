# Post Installation

The first thing is to log into the `cockpit` interface using a browser and connecting to `https://your.ip.address.here:9090` and enable Administrative Mode.

## Updates

Before going any further, update you system using the Terminal available on the WebUI or just use SSH, then run:

```shell
$ sudo dnf upgrade --refresh -y
```

After that reboot the machine to apply the newly installed updates.

### Configure Automatic Updates

Once the server has rebooted, locate the "Software updates" tab in Cockpit and enable automatic updates. Note that this will install the `dnf-automatic` package first, then ask you the type of updates and the time slot in which the server can install them and reboot the system.

## Snapshots

Since we installed the OS onto a BTRFS Filesystem, it is definitely nice to take advantage of its Snapshots capabilities. For this I will use a SUSE Technology: `snapper`.

### Preparation

#### Disable Copy-on-Write

Before proceding, it is advisable to disable the Copy-on-Write functionality of the BTRFS FS in the `/var` directory and its subdirectories. VMs and Containers will have better performances since every write will be on the original file, and not on its copy.

```shell
$ sudo chattr -R -f +C /var
```

And the outcome should be along the lines of what's below:

```shell
$ lsattr /var
---------------C------ /var/lib
lsattr: Operation not supported While reading flags on /var/run
lsattr: Operation not supported While reading flags on /var/lock
---------------C------ /var/adm
---------------C------ /var/cache
---------------C------ /var/db
---------------C------ /var/empty
---------------C------ /var/ftp
---------------C------ /var/games
---------------C------ /var/local
---------------C------ /var/log
---------------C------ /var/nis
---------------C------ /var/opt
---------------C------ /var/preserve
---------------C------ /var/spool
---------------C------ /var/tmp
---------------C------ /var/yp
lsattr: Operation not supported While reading flags on /var/mail
---------------C------ /var/kerberos
---------------C------ /var/crash
---------------C------ /var/account
```

Where the `C` means that CoW has been disabled.

#### Always show GRUB

Another good thing to keep in mind is that by default Fedora hides the Bootloader (GRUB in our case) whenever it is the only Operating System present, showing it only in case of frequent reboots (which I guess are interpreted as mulfunctions). This behaviour can be disabled using this command:

```shell
$ sudo grub2-editenv - unset menu_auto_hide
```

This is documented in the [Fedora Wiki](https://fedoraproject.org/wiki/Changes/HiddenGrubMenu#Detailed_Description).

#### Reduce GRUB Delay

Since you now always show the GRUB bootloader at boot in case it's needed to recover the System, you probably want to reduce the 5-second timer set to boot the default option. My advice is not to set it at 1 or 0 because it might not be shown then (take into account the monitor picking up on the video signal too!), so I generally set it to two seconds. To do that, edit the `/etc/default/grub` file and change the line:

```bash
GRUB_TIMEOUT=5
```

To:

```bash
GRUB_TIMEOUT=2
```

Then re-generate the GRUB configuration:

```shell
$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### Check Subvolumes and adjust flags

Before installing Snapper, let's check our BTRFS Subvolumes:

```shell
$ sudo btrfs subvolume list /

ID 256 gen 246 top level 5 path @usrlocal
ID 257 gen 253 top level 5 path @tmp
ID 258 gen 250 top level 5 path @opt
ID 259 gen 254 top level 5 path @var
ID 260 gen 250 top level 5 path @snapshots
ID 261 gen 53 top level 5 path @media
ID 262 gen 224 top level 5 path @home
ID 263 gen 253 top level 5 path @
ID 264 gen 224 top level 259 path @var/lib/portables
ID 290 gen 224 top level 259 path @var/lib/machines
```

The bottom ones were created automatically by the Fedora Installer. It is plausible that the `/var/lib/portables` and the `/var/lib/machines` subvolumes may not respect the CoW settings we applied earlier, so it is advisable to apply it manually again:

```shell
$ sudo chattr -R -f +C /var/lib/portables
$ sudo chattr -R -f +C /var/lib/machines
```

### Install Snapper

[Snapper](http://snapper.io), to cite from the [openSUSE's Snapper GitHub Repo](https://github.com/openSUSE/snapper), "is     a tool for Linux file system snapshot management. Apart from the obvious creation and deletion of snapshots it can compare snapshots and revert differences between them. In simple terms, this allows root and non-root users to view older versions of files and revert changes.".

To install Snapper, just use:

```shell
$ sudo dnf install snapper
```

If you want Snapper to take snapshots whenever a package is modified through the `dnf` package manager, you can also install `python-dnf-plugin-snapper`.

```shell
$ sudo dnf install python-dnf-plugin-snapper
```

### Configure Root Level Snapshots with Snapper

When creating a configuration for a subvolume, Snapper tends to create a nested subvolume for it called `.snapshots` and mounted in `$SUBVOLUME_MOUNT_POINT/.snapshots`. For root snapshots we would like to use the "top-level" subvolume we created before: `@snapshots`.

To do this without touching the `@snapshots` subvolume, unmount it and delete the `/.snapshots` folder since Snapper will create it and will not proceed if already present:

```bash
$ sudo umount /.snapshots
$ sudo rm -rf /.snapshots
```

This should lead to the same BTRFS subvolume layout as before, but the `@snapshots` volume will not be mounted for the moment. You can verify that nothing actually changed:

```bash
$ sudo btrfs subvolume list /

ID 256 gen 246 top level 5 path @usrlocal
ID 257 gen 253 top level 5 path @tmp
ID 258 gen 250 top level 5 path @opt
ID 259 gen 254 top level 5 path @var
ID 260 gen 250 top level 5 path @snapshots
ID 261 gen 53 top level 5 path @media
ID 262 gen 224 top level 5 path @home
ID 263 gen 253 top level 5 path @
ID 264 gen 224 top level 259 path @var/lib/portables
ID 290 gen 224 top level 259 path @var/lib/machines
```

Now proceed to create the Snapper configuration for the Root FS:

```shell
$ sudo snapper -c root create-config /
```

This will actually create the new subvolume we discussed before:

```bash
$ sudo btrfs subvolume list /

ID 256 gen 246 top level 5 path @usrlocal
ID 257 gen 253 top level 5 path @tmp
ID 258 gen 250 top level 5 path @opt
ID 259 gen 254 top level 5 path @var
ID 260 gen 250 top level 5 path @snapshots
ID 261 gen 53 top level 5 path @media
ID 262 gen 224 top level 5 path @home
ID 263 gen 253 top level 5 path @
ID 264 gen 224 top level 259 path @var/lib/portables
ID 290 gen 224 top level 259 path @var/lib/machines
ID 291 gen 100 top level 263 path /.snapshots
```

We now want to delete it in order to use out top-level subvolume:

```shell
$ sudo btrfs subvolume delete /.snapshots
$ sudo mkdir /.snapshots # Keep in mind that you have to recreate the mount point for @snapshots!
```

This will restore your previous situation:

```shell
$ sudo btrfs subvolume list /

ID 256 gen 246 top level 5 path @usrlocal
ID 257 gen 253 top level 5 path @tmp
ID 258 gen 250 top level 5 path @opt
ID 259 gen 254 top level 5 path @var
ID 260 gen 250 top level 5 path @snapshots
ID 261 gen 53 top level 5 path @media
ID 262 gen 224 top level 5 path @home
ID 263 gen 253 top level 5 path @
ID 264 gen 224 top level 259 path @var/lib/portables
ID 290 gen 224 top level 259 path @var/lib/machines
```

Now re-mount everything according to your `/etc/fstab`:

```shell
$ sudo systemctl daemon-reload
$ sudo mount -a
```

If the `mount` command does not have any error, the configuration worked.

For reference, this is how your `fstab` file should look like if you followed along:

```bash
$ cat /etc/fstab 
# /etc/fstab
# Created by anaconda on Thu Aug  1 21:14:30 2024
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
# Structure
# <UUID>        <Mountpoint>    <fs>    <Mount Options>                         <dump>  <fsck>
# ESP
UUID=redacted   /boot/efi       vfat    umask=0077,shortname=winnt              0       2
# Boot Drive
UUID=redacted   /               btrfs   subvol=@,compress=zstd:1                0       0
UUID=redacted   /.snapshots     btrfs   subvol=@snapshots,compress=zstd:1       0       0
UUID=redacted   /home           btrfs   subvol=@home,compress=zstd:1            0       0
UUID=redacted   /media          btrfs   subvol=@media,compress=zstd:1           0       0
UUID=redacted   /opt            btrfs   subvol=@opt,compress=zstd:1             0       0
UUID=redacted   /tmp            btrfs   subvol=@tmp,compress=zstd:1             0       0
UUID=redacted   /usr/local      btrfs   subvol=@usrlocal,compress=zstd:1        0       0
UUID=redacted   /var            btrfs   subvol=@var,compress=zstd:1             0       0
# Internal HDD
UUID=redacted   /media/HDD      ext4    defaults                                1       2
```

Note that I adjusted the formatting for better readability and redacted some information (also for better readability).

#### Adjust Snapper Configuration for Root Level Snapshots

I personally use this one-liner which changes my desired parameters:

```shell
$ sudo snapper -c root set-config ALLOW_GROUPS=wheel SYNC_ACL=yes TIMELINE_LIMIT_HOURLY="5" TIMELINE_LIMIT_DAILY="7" TIMELINE_LIMIT_WEEKLY="0" TIMELINE_LIMIT_MONTHLY="0"
```

Which is the equivalent of editing the `/etc/snapper/configs/root` file and setting the parameters exactly like in the command.

What it does is:
* `ALLOW_GROUPS=wheel` allows members of the `wheel` group (who uses sudo) to manage the snapshots;
* `SYNC_ACL=yes` syncs the Access Control Lists for the files in the snapshot, essentially transfering permissions;
* `TIMELINE_LIMIT_FREQUENCY="k"` limits the snapshots taken with the desired frequency to `k` before deleting them.

Those parameters were inspired by the [ArchWiki recommendations](https://wiki.archlinux.org/title/Snapper#Set_snapshot_limits).

### Configure Home Snapshots with Snapper

Exactly the same as before, but don't actually bother with top-level subvolumes for Home Snapshots in this case.

```shell
$ sudo snapper -c home create-config /home
$ sudo snapper -c home set-config ALLOW_GROUPS=wheel SYNC_ACL=yes TIMELINE_LIMIT_HOURLY="5" TIMELINE_LIMIT_DAILY="7" TIMELINE_LIMIT_WEEKLY="0" TIMELINE_LIMIT_MONTHLY="0"
```

### Automatic Snapshots

Snapper has three timers which can be enabled with SystemD to automate snapshotting and cleaning beyond installing packages (for example, the timeline snapshots which limits we set-up before).

#### Timeline

```shell
$ sudo systemctl enable --now snapper-timeline.timer
```

#### Boot

```shell
$ sudo systemctl enable --now snapper-boot.timer
```

#### Cleanup

```shell
$ sudo systemctl enable --now snapper-cleanup.timer
```

### GRUB-BTRFS

[GRUB-BTRFS](https://github.com/Antynea/grub-btrfs) is an improvement over the vanilla GRUB Bootloader in that it allows booting from Snapshots (even the read-only ones created with Snapper, if `/var` is on a separate volume like in our case).

#### Install GRUB-BTRFS Dependencies

We need to install `git`, `gawk` and `inotify-tools` in order to proceed.

```shell
$ sudo dnf install git make gawk inotify-tools
```

#### Install GRUB-BTRFS

GRUB-BTRFS is not present in the Fedora Repositories, so we have to compile it from source:

```bash
#!/bin/bash

# Pull the Project Repository
git clone https://github.com/Antynea/grub-btrfs
# Get inside its directory
cd grub-btrfs
# Compile and install
sudo make install
# Clean
cd ../
rm -rf ./grub-btrfs/
```

#### Configure GRUB-BTRFS

The above step should install the GRUB-BTRFS bootloader but will almost certainly result in an error. This is because different distributions position and name GRUB differently. In order to fix it, edit the `/etc/default/grub-btrfs/config` file uncommenting the needed lines as follows:

```bash
[...]

# Location of the folder containing the "grub.cfg" file.
# Might be grub2 on some systems.
# Default: "/boot/grub"
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"

[...]

# Location where grub-btrfs.cfg should be saved.
# Some distributions (like OpenSuSE) store those files at the snapshot directory
# instead of boot. Be aware that this directory must be available for grub during
# startup of the system.
# Default: $GRUB_BTRFS_GRUB_DIRNAME
GRUB_BTRFS_GBTRFS_DIRNAME="/boot/grub2"

[...]

# Name/path of grub-mkconfig command, use by "grub-btrfs.service"
# Might be 'grub2-mkconfig' on some systems (Fedora ...)
# Default paths are /sbin:/bin:/usr/sbin:/usr/bin,
# if your path is missing, report it on the upstream project.
# For example, on Fedora : "/sbin/grub2-mkconfig"
# You can use only name or full path.
# Default: grub-mkconfig
GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig

# Name of grub-script-check command, use by "grub-btrfs"
# Might be 'grub2-script-check' on some systems (Fedora ...)
# For example, on Fedora : "grub2-script-check"
# Default: grub-script-check
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check

[...]
```

Now while regenerating the GRUB configuration everything should work as intended.

```shell
$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

Moreover, GRUB-BTRFS has a SystemD Service which looks for new snapshots inside the `/.snapshots` directory and updates the Bootloader automatically:

```shell
$ sudo systemctl enable --now grub-btrfsd
```

### Create your first Snapshots

This is just to test that everything works as intended.

```shell
$ sudo snapper --config root create --description "First Root Snapshot" --cleanup-algorithm timeline
$ sudo snapper --config home create --description "First Home Snapshot" --cleanup-algorithm timeline
```

It is advisable to now reboot the System.

## Server Performance Logging

In the "Overview" in Cockpit tab there's a "Metrics and history" panel which tells you in real time the CPU and Memory usage of the server.

If you expand the panel, you will quickly find yourself into a more detailed interface, which however will probably tell you that `cockpit-pcp` is missing for Metrics History. It is possible to install it directly from the button right below.

This operation will install four packages:
* `pcp`;
* `pcp-conf`;
* `pcp-libs`;
* `pcp-selinux`.

It is possible to install these packages directly with dnf using the following command:

```shell
$ sudo dnf install pcp pcp-conf pcp-libs pcp-selinux cockpit-pcp
```

And then restart the Cockpit WebUI:

```shell
$ sudo systemctl restart cockpit
```

Once it finishes, log out and log back into the Cockpit Web Interface to enable the Metrics collection and/or export to the network.

## Mount Additional Internal Storage

Create the directory where you want to mount it, oftentimes people mount internal drives in the `/media` directory.

Go to the "Storage" tab, click on your drive and press "Mount". Specify your mountpoint and the drive will be mounted.

If you mount your drive outside of the Home directory, it is advisable to `chown` the folder where it is mounted:

```shell
$ sudo chown -R $(id -u $(whoami)):$(id -g $(whoami)) /your/mount/point
```

## Install QEMU

As per the [Fedora Documentation](https://docs.fedoraproject.org/en-US/fedora-server/virtualization/installation/#_installing_libvirt_virtualization_software), it is possible to add Virtual Machines support through the use of QEMU and KVM and to add this functionality to Cockpit.

```shell
$ sudo dnf install qemu-kvm-core libvirt virt-install cockpit-machines guestfs-tools
```

If you plan on having Windows guest, also install `libguestfs-tools`.

After that, enable the `libvirtd` service and socket:

```shell
$ sudo systemctl enable --now libvirtd
```

The package manager should also have created a Firewall Zone for the newly created Virtual Machines NIC (`vibr0`, a virtual Bridge).

It is now possible to activate the Libvirt Network's service:

```shell
$ sudo  systemctl enable --now virtnetworkd.service
```

And enable all the necessary drivers:

```shell
$ for drv in qemu interface network nodedev nwfilter secret storage ; \
  do sudo systemctl enable --now virt${drv}d{,-ro,-admin}.socket ;  done
```

Add yourself to the qemu and libvirt groups:

```shell
$ sudo usermod -aG qemu $(whoami)
$ sudo usermod -aG libvirt $(whoami)
```

Finally, reboot your system.

## Install Docker

It is a really straight forward procedure thanks to [Docker's Official Documentation](https://docs.docker.com/engine/install/fedora/).

```bash
#!/bin/bash

# Install the dnf-plugins-core package
sudo dnf -y install dnf-plugins-core
# Add the Docker Repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
# Install Docker, Docker Compose and their plugins
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Enable the Docker Service
sudo systemctl enable --now docker
# Add your user to the Docker Group
sudo usermod -aG docker $(whoami)
```

The Docker installation should also create a new zone inside the Firewall.

Finally, reboot the machine and you should be up and running.
