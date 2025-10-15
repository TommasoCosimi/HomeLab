# Installation
## System Role
Use the Server option as the System Role.

## Partitioning
When partitioning, use first the guided setup to partition the boot drive, then run modifications with with the "Expert Partitioner" and "Start from the Current Proposal" oprtion:
- Add a `@/media` subvolume with CoW Disabled to the BTRFS Volume that mounts into `/`;
- Mount the Storage Hard Drive - which is formatted using the EXT4 File System - into `/media/HDD`.

## User Settings
### User Creation
Create your non privileged user, give it a strong password, and uncheck the option to use the same password for the Administrator.

### Root User Password
Give this user a **different** strong password.

## Installation Settings
### Booting
Enable Trusted Boot Support. Optionally, it is possible to move to the "Bootloader Options" tab to disable probing for foreign OSes and lower the countdown for the boot process (I typically leave it to 2 seconds to have time to operate in case it's needed).

### Software
Add the pattern for [Cockpit](https://cockpit-project.org/). The Firewall will be automatically configured to open its port (`9090`) in order to be able to access it.

### Security
Disable the SSH Service and block via the Firewall (which is [FirewallD](https://firewalld.org/)) its port. A custom port will be used.


# Post Installation
## Networking
To edit such settings, use the Cockpit web interface, log into `https://your.server.local.address:9090` using your user credentials and allow Administrative Access using the root account password.

### Hostname
In the "Overview" tab, use the "Configuration" card to set up your preferred Hostname.

### Bridge Interface
In the "Networking" tab add a new Bridge Interface using the appropriate button and give it a name. This interface will manage your phisical interface, so make sure to include it.

> **Note**: Since we are still using DHCP there's the possibility that the new bridge interface will have a different IP from before, in that case you will have to log in again and allow Administrative Access.

### Static Local IP
Click on the newly created bridge interface and set up IPv4 and IPv6 addresses as desired.

Once that is done, a connection test will be ran. It will most probably succeed, and ask you if you want to apply the new settings even if it means you have to disconnect. You can accept this possibility and still use the Cockpit instance on the previous DHCP-provided IP Address until the next reboot.

## User setup
Using the "Terminal" tab to execute commands, add yourself to the `wheel` group.
```bash
sudo usermod -aG wheel $(whoami)
```
And using `visudo` to edit the `/etc/sudoers` file uncomment the following line:
```bash
%wheel ALL=(ALL:ALL) ALL
```
This allows members of the group `wheel` to run any command with `sudo` behind password authentication.

Finally, comment these other lines:
```bash
Defaults targetpw   # ask for the password of the target user i.e. root
ALL   ALL=(ALL) ALL   # WARNING! Only use this together with 'Defaults targetpw'!
```
Logout or restart to apply the changes.

## Owning the Internal Drive
The owner of the internal drive will by default be `root`. To be able to run commands on it without using `sudo`, it is possible to change the ownership of the drive mountpoint:
```bash
sudo chown -R $(whoami):$(whoami) /media/HDD
```

## System Update
Probably not needed if you used a Network Install medium, but still recommended:
```bash
sudo zypper dup
```

## Optional: enable ZRAM
It is possible to enable ZRAM using Systemd.
```bash
sudo zypper install systemd-zram-service
sudo systemctl enable --now zramswap.service
```

## Fail2Ban
The usage of [Fail2Ban](https://github.com/fail2ban/fail2ban) is highly recommended for securing the system against login attempts from attackers. In this case the default options will be used.
```bash
sudo zypper install fail2ban
sudo systemctl enable --now fail2ban
```

## SSH Settings
Edit the `/usr/etc/ssh/sshd_config` file.
The next sections will list the necessary lines to edit (and eventually uncomment if needed) and their final value.

### Custom Port
```bash
Port yournewportnumber
```

### Disable Root Login
```bash
PermitRootLogin no
```

### Disable Password Authentication
```bash
PasswordAuthentication no
```

### Allow the new SSH Port through the Firewall
In the "Networking" tab click on the "Edit Rules and Zones" button in the "Firewall" section.

Using the "Add services" button, add Custom Ports to the Public zone (which is the default zone) as instructed:
- TCP: The `yournewportnumber` that you set up earlier;
- UDP: Leave empty, SSH uses TCP only;
- ID: Gives this rule a name, it is auto-generated but you can customize it;
- Description: Can be left empty, but it's recommended to describe the functionality.

The firewall does not need to be reloaded manually since Cockpit takes care of everything by itself.

### Add your host Public Key using Cockpit
#### Prerequisite
You should have a private/public Key pair for SSH logins on your host. If you don't, on the host machine run:
```bash
ssh-keygen -t yourpreferredalgorithm
```
Where `yourpreferredalgorithm` can be one of the following:
- dsa
- ecdsa
- ecdsa-sk
- ed25519
- ed25519-sk
- rsa

#### Copying the Public Key
You can view the contents of the public key by running:
```bash
cat .ssh/id-yourpreferredalgorithm.pub
``` 

#### Adding the Public Key to the Server
On the server, go to the "Accounts" tab of the Cockpit interface, click on your Username and use the "Add key" button to add your host's key.

### Enable the SSH Service
Enable the `sshd` Systemd Service:
```bash
sudo systemctl enable --now sshd
```

Now you should be able to use SSH to connect to your server by running on the host:
```bash
ssh -p yournewportnumber your_username@your.server.local.address
```

## Automatic Updates
It is possible to use the `os-updates` package directly from openSUSE and tweak its settings to accomodate our necessities.
```bash
sudo zypper install os-updates
```

### Performing Updates
Create an `/etc/os-update.conf` file with the following contents:
```bash
UPDATE_CMD="dup"
```

### Setting up the Update Schedule
Edit the Systemd timer (`/usr/lib/systemd/system/os-update.timer`) in the following manner:
```bash
your_username@server-hostname:~> cat /usr/lib/systemd/system/os-update.timer
[Unit]
Description=Daily update of Host OS
After=network.target local-fs.target
Wants=network-online.target
Conflicts=transactional-update.timer

[Timer]
OnCalendar=*-*-* 03:00:00 # Everyday at 3AM, you can tweak this

[Install]
WantedBy=timers.target
```
For a more in-depth look into Systemd Timers, read the [ArchWiki](https://wiki.archlinux.org/title/Systemd/Timers).

Finally, enable the service:
```bash
sudo systemctl enable os-update.timer
```

## Performance Profiles
Even though `tuned` is installed from the beginning, it is not enabled by default. To use it:
```bash
sudo systemctl enable --now tuned
```

## Performance Logging
To enable performance logging in Cockpit you can use `pcp`.
```bash
sudo zypper install pcp python3-pcp
sudo systemctl enable --now pmlogger
```


# Hosting Services
The idea behind this setup is to use [Incus](https://linuxcontainers.org/incus/docs/main/) to spin up containers which can either host applications or another containerization tool such as [Docker](https://www.docker.com/) which then manages its containers in a nested environment.

## Installing Incus
> **Note**: Everything has been taken from the Incus' Documentation if not otherwise specified.

It is possible to run the following commands to install incus and setup user permissions:
```bash
sudo zypper in incus # To install Incus
sudo usermod -aG incus $(whoami) # Add your user to the incus group
sudo usermod -aG incus-admin $(whoami) # Add your user to the incus administrators group
```
You can then either log out and log back in to apply the groups changes or use the commands below.
```bash
newgrp incus
newgrp incus-admin
```
Once you belong to these groups, it is possible to proceed

## Initialize Incus
Start by enabling the Incus Socket:
```bash
sudo systemctl enable --now incus.socket
```
Then proceed with the initialization procedure with:
```bash
incus admin init
```
and answering the questions interactively. An extremely simple and minimal example is reported below.
```bash
your_username@server-hostname:~> incus admin init
Would you like to use clustering? (yes/no) [default=no]: 
Do you want to configure a new storage pool? (yes/no) [default=yes]: 
Name of the new storage pool [default=default]: 
Name of the storage backend to use (dir, lvm, lvmcluster, btrfs) [default=btrfs]: 
Would you like to create a new btrfs subvolume under /var/lib/incus? (yes/no) [default=yes]: 
Would you like to create a new local network bridge? (yes/no) [default=yes]: 
What should the new bridge be called? [default=incusbr0]: 
What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: 
Would you like the server to be available over the network? (yes/no) [default=no]: 
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]: 
Would you like a YAML "init" preseed to be printed? (yes/no) [default=no]: 
```

## Optional: Change the `incusbr0` Network Address Space
You can change the IPv4 subnet to use for the default bridge network if you don't like the auto-generated one:
```bash
incus network set incusbr0 ipv4.address subnet.gateway.ip.address/mask # Example: 192.168.1.1/24
```
To limit the attack surface I disable IPv6, but it can be an interesting development to use it nonetheless:
```bash
incus network set incusbr0 ipv6.address none
```

## Manage the `incusbr0` Network through FirewallD
> **Note 1**: This is applicable for every bridge network which is managed by Incus.

> **Note 2**: The following implementation is a personal readaptation of the instructions found in the [Incus Wiki page about Firewall Configuration in Bridge Networks](https://linuxcontainers.org/incus/docs/main/howto/network_bridge_firewalld/#use-another-firewall) which were written for `ufw`.

As a first step, it is necessary to disable Incus' firewall for its managed network `incusbr0`:
```shell
incus network set incusbr0 ipv4.firewall false
incus network set incusbr0 ipv6.firewall false
```

### Create a zone for the Incus interfaces
Create the new Firewall zone:
```bash
sudo firewall-cmd --new-zone=incus --permanent
sudo firewall-cmd --reload
```
Add the desired interface to the zone (in this case `incusbr0`):
```bash
sudo firewall-cmd --add-interface=incusbr0 --zone=incus --permanent
sudo firewall-cmd --reload
```

### Configure the zone to allow for DNS and DHCP
```bash
sudo firewall-cmd --zone=incus --add-service=dns --add-service=dhcp --permanent
sudo firewall-cmd --zone=incus --add-service=dhcpv6 # If you use IPv6
sudo firewall-cmd --reload
```

### Optional: allow internet access to containers using the bridged network in the new zone
Add rich rules for packet forwarding to the `incus` zone:
```bash
sudo firewall-cmd --permanent --zone=incus --add-rich-rule='rule family="ipv4" source address="subnet.ipv4.address.space/mask" accept'
sudo firewall-cmd --permanent --zone=incus --add-rich-rule='rule family="ipv6" source address="subnet.ipv6.address.space/mask" accept' # If you use IPv6
sudo firewall-cmd --reload
```
Change the target for the `incus` zone:
```bash
sudo firewall-cmd --set-target=ACCEPT --zone=incus --permanent
sudo firewall-cmd --reload
```
Add masquerading to the default zone:
```bash
sudo firewall-cmd --add-masquerade --zone=public --permanent
sudo firewall-cmd --reload
```
Finally, you should get the following configuration for the firewall zones in use (IPv6 not used in this case):
```bash
your_username@server-hostname:~> sudo firewall-cmd --list-all-zones 
[...]
incus (active)
  target: ACCEPT
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: incusbr0
  sources: 
  services: dhcp dns
  ports: 
  protocols: 
  forward: no
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
        rule family="ipv4" source address="subnet.ipv4.address.space/mask" accept
[...]
public (default, active)
  target: default
  ingress-priority: 0
  egress-priority: 0
  icmp-block-inversion: no
  interfaces: *redacted*
  sources: 
  services: *redacted*
  ports: 
  protocols: 
  forward: yes
  masquerade: yes
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
[...]  
```
To test if everything is working, you can spin up a container and ping an address or a domain name as shown in the toy example below:
```shell
your_username@server-hostname:~> incus launch images:debian/trixie test
Launching test
your_username@server-hostname:~> incus list              
+------+---------+-------------------+------+-----------+-----------+
| NAME |  STATE  |       IPV4        | IPV6 |   TYPE    | SNAPSHOTS |
+------+---------+-------------------+------+-----------+-----------+
| test | RUNNING | x.y.z.a (eth0)    |      | CONTAINER | 0         |
+------+---------+-------------------+------+-----------+-----------+
your_username@server-hostname:~> incus shell test 
root@test:~# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=112 time=26.1 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=112 time=28.0 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=112 time=25.8 ms
^C
--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 25.813/26.639/28.026/0.986 ms
root@test:~# exit
logout
```

## Manage Incus Profiles
For the intended usage I want to have two profiles:
- `default` which lets Containers and VMs managed through Incus to connect to the `incusbr0` network only (it's as the name suggests the default profile created at initialization time, and can be left as is);
- `bridge_lan` which interfaces such containers with my Local Area Network only.

Because of the way profiles work on Incus, what's done is that we declare the changes from the `default` profile - which is treated as a baseline - in the other profiles.

### `bridge_lan` Profile
Replaces the `eth0` device settings in the `default` profile to accomodate for the usage of the host's bridge interface.
```bash
incus profile create bridge_lan
incus profile device add bridge_lan eth0 nic nictype=bridged parent=your_bridge_interface
```

## Setup Docker Host
The Docker Host will be an unprivileged container and will use the `default` profile, but - as it's illustrated by Luigi Castro in [this comment](https://discuss.linuxcontainers.org/t/using-docker-with-incus/19801) of the [LinuxContainers.org](https://linuxcontainers.org/) forum, combined with explainations from the [nixCraft](https://www.cyberciti.biz/faq/how-to-run-docker-inside-incus-containers/) website - will need some configurations to be able to use the nesting capabilities it needs:
- `boot.autostart=true` to start automatically at boot time;
- `security.nesting=true` to allow for the Nesting capability itself;
- `security.syscalls.intercept.mknod=true` to allow the mknod and mknodat Linux system calls to create a variety of special files safely inside Incus for Docker; 
- `security.syscalls.intercept.setxattr=true` to allow the setxattr Linux system call to set extended attributes on files safely inside Incus for Docker.

The distribution of choice will be the latest Debian Stable release (13 Trixie at the time of writing). This choice is mostly because of its proverbial stability.

### Crete the Container
Create the container:
```bash 
incus launch images:debian/trixie DockerHost -c boot.autostart=true -c security.nesting=true -c security.syscalls.intercept.mknod=true -c security.syscalls.intercept.setxattr=true
```
Enter the container using the `root` account:
```bash
incus shell DockerHost
```
Now you are in the container's shell, and can start setting up what comes next.

### Set up a `root` password
Using the `passwd` command:
```shell
root@DockerHost:~# passwd
New password: 
Retype new password: 
passwd: password updated successfully
```
Give the root account a **different** and **strong** password.

### Create an unprivileged user
Create the user, again giving it a **different** and **strong** password:
```bash
adduser user
```
Grant the user `sudo` privileges:
```bash
usermod -aG sudo user
```

### Set up a static address
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
Remove every unneded service from the zone, minimizing the open ports. Docker will use its rules to open other necessary ports for its services.
```bash
firewall-cmd --zone=public --remove-service=ssh --remove-service=dhcpv6-client --permanent
```
Finally, reload the firewall:
```bash
firewall-cmd --reload
```

### Install Docker
Directly from the [Docker documentation](https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script):
```bash
apt -y install curl
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```
Add the user to the docker group in order to run most docker commands without the use of `sudo`:
```bash
usermod -aG docker user
```

### Bind mount the Container folder
My setup makes use of folders in the Hard Drive to store the containers files and their respective data.

Using the information in the [Wiki](https://linuxcontainers.org/incus/docs/main/reference/devices_disk/) and in [
Simos Xenitellis's blog](https://blog.simos.info/how-to-share-a-folder-between-a-host-and-a-container-in-incus/) it is possible to share a directory on the host while preserving the permissions using the following command:
```bash
incus config device add DockerHost Host_Share disk source=/source/path path=/destination/path shift=true
```

## Forward traffic to the Docker Containers
Since these Docker containers live on a different host than the physical one, it is necessary to forward request which are intended for them from the physical host itself.

To achieve that, using the [FirewallD Documentation](https://firewalld.org/2024/11/strict-forward-ports), the following command can be ran:
```bash
firewall-cmd --zone=public --add-forward-port=port=hostport:proto=<protocol>:toport=dockerhostport:toaddr=docker.host.container.ip --permanent
firewall-cmd --reload
```

## Docker Networks
This project uses two networks:
- `services` to make the containers interface with the Reverse Proxy without being exposed to the outside network;
- `external` to be able to communicate with the other Incus Containers and Hosts in the physical LAN.

To create them:
```bash
sudo docker network create \
    -d bridge \
    --subnet your.desired.address.space \
    --gateway your.desired.gateway.address \
    services

sudo docker network create \
    -d ipvlan \
    -o parent=yourInterfaceName \
    --subnet your.external.network.subnet/mask \
    --gateway your.external.network.gatway \
    incusnet
```