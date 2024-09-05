# Fedora 40 Installation

The installation procedure is pretty standard and the only three deviations from a default installation have been:
* User Creation;
* Network Configuration;
* Applications to install;
* Disk Partitioning.

## User Configuration

Create a new Non-Root User and don't create a Root Account.

## Network Configuration

### Changing the Hostname

Use the lower left text field to change the Hostname to something recognizable.

### Setting a Static Local IP Address

By changing the Network Connection Settings i managed to set a static local IPv4 Address in the IPv4 Tab. DNS Servers are set to [Quad9](https://quad9.net).

## Applications to install

The only bundle selected is "Headless Management", which installs tools like `cockpit`, a Web GUI for our server.

## Disk Partitioning

With the intention to set up automatic snapshots on the boot drive, the partition table looks as follows:

|   **Device**   | **Format** | **Mountpoint** |
|:--------------:|:----------:|:--------------:|
| /dev/nvme0n1p1 | EFI        | /boot/efi      |
| /dev/nvme0n1p2 | btrfs      | No Mountpoint  |

Then, expanding on the `btrfs` Volume, it has been split into multiple subvolumes: 
* `@` for the Root Filesystem;
* `@home` for the Users' Home folders;
* `@snapshots` to accomodate for the Root FS Snapshots (it will be manipulated later);
* `@media` for external Drives
* `@var` to preserve variable files such as logs, caches, but also Virtual Machines and Docker Containers;
* `@opt` typically contains third-party program we'd want to preserve in case of rollback;
* `@tmp` for temporary files, especially logs;
* `@usrlocal` to preserve manually installed software;
* `@swap` to allow for Swapfiles to be used and not be snapshotted.

After the install a new subvolume `@root`, which will be mounted into `/root`, will be created to account for the Home Folder of the root account. It will be done after the install is complete because the Anaconda Installer doesn't let you do it at install time.

The Subvolume Layout was largely inspired by the [openSUSE guidelines](https://en.opensuse.org/SDB:BTRFS) and the [Arch guidelines](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout).

| **BTRFS Subvolume** | **Format** | **Mountpoint** |
|:-------------------:|:----------:|:--------------:|
| @                   | btrfs      | /              |
| @home               | btrfs      | /home          |
| @snapshots          | btrfs      | /.snapshots    |
| @media              | btrfs      | /media         |
| @var                | btrfs      | /var           |
| @opt                | btrfs      | /opt           |
| @tmp                | btrfs      | /tmp           |
| @usrlocal           | btrfs      | /usr/local     |
| @swap               | btrfs      | /swap          |

It is now possible to proceed with the installation.