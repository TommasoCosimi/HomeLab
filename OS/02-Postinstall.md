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

## Server Performance Logging

In the "Overview" tab there's a "Metrics and history" panel which tells you in real time the CPU and Memory usage of the server.

If you expand the panel, you will quickly find yourself into a more detailed interface, which however will probably tell you that `cockpit-pcp` is missing for Metrics History. It is possible to install it directly from the button right below.

This operation will install four packages:
* `pcp`;
* `pcp-conf`;
* `pcp-libs`;
* `pcp-selinux`.

Once it finishes, log out and log back into the Cockpit Web Interface to enable the Metrics collection and/or export to the network.

## Mount Additional Internal Storage

Create the directory where you want to mount it, oftentimes people mount internal drives in the `/media` directory.

Go to the "Storage" tab, click on your drive and press "Mount". Specify your mountpoint and the drive will be mounted.

If you mount your drive outside of the Home directory, it is advisable to `chown` the folder where it is mounted:

```shell
$ sudo chown -R $(id -u $(whoami)):$(id -g $(whoami)) /your/mount/point
```

## Install QEMU

As per the [Fedora Documentation](https://docs.fedoraproject.org/en-US/fedora-server/virtualization/installation/#_installing_libvirt_virtualization_software), it is possible to add Virtual Machines support through the use of QEMU and KVM and to add this functionality to Cockpit through the execution of this command:

```shell
$ sudo dnf install qemu-kvm-core libvirt virt-install cockpit-machines guestfs-tools
```

If you plan on virtualizing Windows machines, also install `libguestfs-tools`.

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
  do systemctl start virt${drv}d{,-ro,-admin}.socket ;  done
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
sudo systemctl enable docker
# Add your user to the Docker Group
sudo usermod -aG docker $(whoami)
```

The Docker installation should also create a new zone inside the Firewall.

Finally, reboot the machine and you should be up and running.