# Kasm Workspaces
Kasm is a self-hostable container streaming platform that works directly inside any web browser.

## Setup the Kasm Container
The Kasm container configuration will be similar to the one for the Docker Host.

### Crete the Container
Create the container:
```bash 
incus launch images:debian/trixie Kasm -c boot.autostart=true -c security.nesting=true -c security.syscalls.intercept.mknod=true -c security.syscalls.intercept.setxattr=true
```
Enter the container using the `root` account:
```bash
incus shell Kasm
```
Now you are in the container's shell, and can start setting up what comes next.

### Set up a `root` password
Using the `passwd` command:
```shell
root@Kasm:~# passwd
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
Add accepted sources of packets.
```bash
firewall-cmd --zone=public --add-source=a.b.c.d/e --permanent # For your subnet
```
Set the policy to drop:
```bash
firewall-cmd --set-target=DROP --zone=public --permanent
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

### Install Kasm
Using the [Single Server installation guide in the Documentation](https://www.kasmweb.com/docs/latest/install/single_server_install.html#installation-guide) it is possible to esily install the server by following the given commands, eventually setting a custom listening port for improved security.

### Reverse Proxies
If running behind a reverse proxy, once everything is set up you may not be able to connect to the container instances.

To fix this, following the [Reverse Proxy Documentation for Kasm](https://www.kasmweb.com/docs/latest/how_to/reverse_proxy.html#update-zones), you just have to update the Proxy Port value to "`0`".