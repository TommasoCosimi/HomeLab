# PiHole
PiHole is a DNS Sinkhole, which can act as a Recursive DNS Server and DHCP Client.

In my usecase it will be used as a DNS Sinkhole which will make DoH requests using Cloudflared.

An Incus container will be used to set up PiHole.

## Crete the Container
Create the container:
```bash 
incus launch images:debian/trixie PiHole -c boot.autostart=true --profile default --profile bridge_lan
```
Enter the container using the `root` account:
```bash
incus shell PiHole
```
Now you are in the container's shell, and can start setting up what comes next.

## Set up a `root` password
Using the `passwd` command:
```shell
root@PiHole:~# passwd
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
firewall-cmd --zone=public --remove-service=ssh --remove-service=dhcpv6-client --permanent
firewall-cmd --zone=public --add-service=http --add-service=dns --permanent
```
Finally, reload the firewall:
```bash
firewall-cmd --reload
```

### Install PiHole
From the [documentation](https://docs.pi-hole.net/main/basic-install/):
```bash
apt -y install curl
curl -sSL https://install.pi-hole.net | bash
```
It is possible to then follow the on-screen instructions to choose the DNS Provider and the logging level.

Once that is done, it is better to continue using the unprivileged account.

#### Disable NTP Server
In the "Settings" tab enable the "expert" switch and get inside the "All settings" sub-tab, where you can disable the NTP Server functionality.

### Enable DoH with Cloudflared
Using `cloudflared` it is possible to enable DNS over HTTPS by following the PiHole [documentation](https://docs.pi-hole.net/guides/dns/cloudflared/).
```bash
sudo apt -y install wget
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo apt-get install ./cloudflared-linux-amd64.deb
```
Create a user to use Cloudflared and make it start at bootup:
```bash
sudo useradd -s /usr/sbin/nologin -r -M cloudflared
```
Configure Cloudflared by modifying `/etc/default/cloudflared` (configuration taken from the [Quad9 documentation](https://docs.quad9.net/Setup_Guides/Miscellaneous/Cloudflared_and_Quad9/)):
```bash
CLOUDFLARED_OPTS=--port 5053 --upstream https://9.9.9.9/dns-query --upstream https://149.112.112.112/dns-query
```
And let the `cloudflared` user own the modified file:
```bash
sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared
```
Then create a Systemd service which will start Cloudflared with the correct settings in `/etc/systemd/system/cloudflared.service`:
```bash
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
```
And finally enable and start such service:
```bash
sudo systemctl enable --now cloudflared
```
Once everything is done, enable it in the WebUI as illustrated in the documentation.