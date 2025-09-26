# Syncthing
Syncthing is a continuous file synchronization program. It synchronizes files between two or more computers in real time, safely protected from prying eyes. From the [Syncthing website](https://syncthing.net/).

An Incus container will be used to set up Syncthing.

## Crete the Container
Create the container:
```bash 
incus launch images:debian/trixie Syncthing -c boot.autostart=true --profile default --profile bridge_lan
```
Enter the container using the `root` account:
```bash
incus shell Syncthing
```
Now you are in the container's shell, and can start setting up what comes next.

## Set up a `root` password
Using the `passwd` command:
```shell
root@Syncthing:~# passwd
New password: 
Retype new password: 
passwd: password updated successfully
```
Give the root account a **different** and **strong** password.

## Create an unprivileged user
Create the user, again giving it a **different** and **strong** password:
```bash
adduser user
```
Grant the user `sudo` privileges:
```bash
usermod -aG sudo user
```

## Set up a static address
Edit the `/etc/systemd/network/eth0.network` file (with `eth0` being the name of the interface we need).

Change the lines:
```ini
[Match]
Name=eth0

[Network]
DHCP=true

[DHCPv4]
UseDomains=true
UseMTU=true

[DHCP]
ClientIdentifier=mac
```
To:
```ini
[Match]
Name=eth0

[Network]
Address=your.desired.address.here/netmask
Gateway=your.default.gateway.address
DNS=your.default.dns.address
```

### Install and configure a Firewall for the container
FirewallD will be again the firewall of choice:
```bash
apt -y install firewalld
systemctl enable --now firewalld
```
Add the interface to the "public" zone:
```bash
firewall-cmd --add-interface=eth0 --zone=public --permanent
```
Remove every unneded service from the zone, minimizing the open ports.
```bash
firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent
firewall-cmd --zone=public --add-service=syncthing --permanent
```
Finally, reload the firewall:
```bash
firewall-cmd --reload
```

### Install Syncthing
From there on it is advisable to use the unprivileged user.

First of all, Syncthing has to be installed and its service enabled:
```bash
sudo apt -y install syncthing
sudo systemctl enable --now syncthing@user
```
Now to access the WebUI without exposing it to the outside, it is possible to use an SSH connection to forward all of the requests to a specific port of a separate device to the Syncthing server as explained in the [Arch Linux Manual](https://man.archlinux.org/man/extra/syncthing/syncthing-networking.7.en#Tunneling_via_SSH).
```bash
sudo apt -y install ssh # Install the SSH Server
sudo systemctl start sshd # Start the SSH Server, but don't make it persistent
```
And on the other device run:
```bash
ssh -L 9999:localhost:8384 user@syncthing.server.ip.address
```
Accessing `localhost:9999` in the other device's browser will result in the WebGUI for the Syncthing server to appear.

Once the operations in the WebUI are done, it is possible to stop the SSH service on the Syncthing container.