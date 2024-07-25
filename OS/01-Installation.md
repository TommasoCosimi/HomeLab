# Fedora 40 Installation

The installation procedure is pretty standard and the only three deviations from a default installation have been:
* Network Configuration;
* Applications to install;
* Disk Partitioning.

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

Then, expanding on the `btrfs` partition, it has been split into two subvolumes: `@root` and `@home`.

| **BTRFS Subvolume** | **Format** | **Mountpoint** |
|:-------------------:|:----------:|:--------------:|
| @root               | btrfs      | /              |
| @home               | btrfs      | /home          |

After the installation is complete and the software is in place, more subvolumes will be created.