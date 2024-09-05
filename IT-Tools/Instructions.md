# IT-Tools

IT-Tools is a set of useful tools for developers.

## The Container

The Docker Compose file should look as follows:

```yaml
services:
  it-tools:
    image: 'corentinth/it-tools:latest'
    restart: unless-stopped
    container_name: it-tools
    networks:
      services:
        ipv4_address: your.desired.ip.address

networks:
  services:
    name: services
    external: true
```

The above configuration is essentially the default one available [here](https://github.com/CorentinTh/it-tools) converted to compose using the included tool with minor tweaks (essentially just the `services` Network).