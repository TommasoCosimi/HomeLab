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
    container_name: kasm
    privileged: true
    environment:
      - KASM_PORT=443
      - DOCKER_MTU=1500
    volumes:
      - kasm_data:/opt
      - kasm_profiles:/profiles #optional
      - /dev/input:/dev/input #optional
      - /run/udev/data:/run/udev/data #optional
    networks:
      services:
        ipv4_address: your.desired.address.here
    restart: unless-stopped

volumes:
  kasm_data:
    external: true
  kasm_profiles:
    external: true

networks:
  services:
    name: services
    external: true
```

The above configuration has been planned using the [linuxserver.io GitHub Repository for Kasm](https://github.com/linuxserver/docker-kasm).

## Setup
Before accessing the Kasm Workspaces application at port `8443` it is necessary to set it up by using its port `3000`, where the setup is.