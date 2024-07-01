# Nginx Proxy Manager Installation

Nginx Proxy Manager will be used to have domain names and to have working SSL Certificates.


## The container

The Proxy Manager will run in a Debian 12 LXC Container with the following specifications:
* 1 CPU Core;
* 512MB RAM + 512MB of Swap Space;
* 4GB of Disk Space.


## First boot and setup

### Updates

First off, the OS got updated:

```console
root@NginxProxyManager# apt update && apt full-upgrade -y
```

Then I proceded restarting the container to fully apply the updates.

### Non-Root User

At this point I wanted to add a non-root user to the system, so I installed `sudo`:

```console
root@NginxProxyManager# apt install -y sudo
```

And then I created a new user, which I added to the `sudo` group:

```console
root@NginxProxyManager# adduser npm
root@NginxProxyManager# usermod -aG sudo npm
```

At this point I could login as non-root, and test if the configuration worked:

```console
npm@NginxProxyManager:~$ sudo apt update
[sudo] password for npm: 
Hit:1 http://security.debian.org bookworm-security InRelease
Hit:2 http://deb.debian.org/debian bookworm InRelease
Hit:3 http://deb.debian.org/debian bookworm-updates InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.https://forum.proxmox.com/members/bill-mcgonigle.61031/
```


## Installing Nginx Proxy Manager

Using [Elton Renda](https://github.com/ej52)'s guide (available in his [proxmox-scripts](https://github.com/ej52/proxmox-scripts) repository), it's as easy as executing this command:

```bash
sudo sh -c "$(wget --no-cache -qO- https://raw.githubusercontent.com/ej52/proxmox/main/install.sh)" -s --app nginx-proxy-manager
```

Which should lead to the URL of the service once it has finished.


## Login and first use

For the first usage, login with the default credentials:

```
Username: admin@example.com
Password: changeme
```

And follow the on-screen instructions to create your User Account with Administrator Privileges.