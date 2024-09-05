# Kasm Workspaces

[Kasm Workspaces](https://www.kasmweb.com/) is a service which allows to run and stream containerized Applications and Operating Systems.

## The Container

### Volumes

The Docker Container needs two locations where to store permanent data, this time for ease of use though, those are chosen to be local folders.

### Compose file

The Docker Compose file should look as follows:

```yaml
services:
  kasm:
    image: lscr.io/linuxserver/kasm:latest
    restart: unless-stopped
    container_name: kasm-workspaces
    privileged: true
    networks:
      services:
        ipv4_address: your.desired.ip.address
    environment:
      - KASM_PORT=8443
    volumes:
      - /your/desired/path/Kasm-Workspaces/data:/opt
      - /your/desired/path/Kasm-Workspaces/profiles:/profiles
      - /dev/input:/dev/input
      - /run/udev/data:/run/udev/data

networks:
  services:
    name: services
    external: true
```

The above configuration has been planned using the [linuxserver.io GitHub Repository for Kasm](https://github.com/linuxserver/docker-kasm).

## Setup

Before accessing the Kasm Workspaces application at port `8443` it is necessary to set it up by using its port `3000`, where the setup is.