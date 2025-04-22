# ZeroTier

Since my home network is behind a [Carrier-Grade NAT](https://en.wikipedia.org/wiki/Carrier-grade_NAT), it is simpler (and cheaper) for me to use a Software Defined WAN like [ZeroTier](https://www.zerotier.com/product/) to access it from outside.

Since I want to keep the services I am going to self host just inside my Home Network, I needed a machine which would route traffic from the ZeroTier Virtual LAN to my physical Home LAN.

This functionality will be unwound by a Docker Container.

## ZeroTier Network

Just create a new Network [here](https://my.zerotier.com/network) with default settings.

## The Container

### The Container Image

Largely taking inspiration from [this AddictiveTips article](https://www.addictivetips.com/ubuntu-linux-tips/how-to-use-zerotier-in-docker-on-linux/) I set up a custom Debian Image inside Portainer to be able to later use it in a Docker Compose file called `zerotier-debian`.

It can be created using this Dockerfile (also available in the `Docker` subfolder of this service):

```Dockerfile
# Use Debian as a base
FROM debian:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Configure and install
# What commands do:
# 1. Allow for Packet Forwarding
# 2. Update the system
# 3. Install necessary packets and iproute2 (Quality of Life improvement)
# 4. Install ZeroTier
RUN echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf && \
    apt update && apt full-upgrade -y && \
    apt install -y curl gnupg iproute2 iptables iptables-persistent && \
    curl -s https://install.zerotier.com | bash

# Ensure the ZeroTier service starts automatically
CMD service zerotier-one start && tail -f /dev/null
```

And later running the command:

```shell
$ sudo docker build -t zerotier-debian:latest
```

### Compose File

After the image was created, it is possible to create a Stack inside Portainer to spin up the container:

```yaml
services:
  zerotier:
    image: zerotier-debian:latest
    restart: unless-stopped
    container_name: zerotier
    devices:
      - /dev/net/tun:/dev/net/tun
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
```

This instance doesn't really need additional storage, but needs the `NET_ADMIN` and `SYS_ADMIN` capabilities to be able to configure network interfaces and route traffic correctly. Other than that, it needs to use the Host Network TUNnel device.

## Joining the ZeroTier Network

Joining a network is just a matter of running the command below:

```shell
$ sudo zerotier-cli join NETWORK_ID
```

To which the expected output if everything goes well is `200 join OK`. Note that you have to replace the `NETWORK_ID` variable with the effective ID of your ZeroTier Network.

Before going any further you should authorize your Server on the Network using the Web Dashboard at the link `https://my.zerotier.com/network/NETWORK_ID`.

To check that everything is working just run the following:

```shell
$ sudo zerotier-cli listnetworks
```

If everything is ok, the output should be similar to what is listed below:

```console
zt@ZeroTier:~$ sudo zerotier-cli listnetworks
[sudo] password for zt: 
200 listnetworks <nwid> <name> <mac> <status> <type> <dev> <ZT assigned ips>
200 listnetworks NetworkID HomeLab MA:C_:AD:DR:ES:S_ OK PRIVATE ztdummyname 192.168.196.1/24
```

## Manage Routes to Home Network in the ZeroTier Dashboard

In the `Advanced` tab look for the `Managed Routes` menu. Add to the `Destination` your Network subnet in CIDR Notation (for example `192.168.1.0/24`), and in the `Via` field write down the IP of your server. It should look something like this:

![Routes](Routes.png)

After that you can click on the "Submit" button to apply your rule.


## Enable routing IPs

```shell
#!/bin/bash

ZT_IFACE="$(ls /sys/class/net | grep zt)"
PHY_IFACE=br0

iptables -t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT
bash -c iptables-save > /etc/iptables/rules.v4
```