# Syncthing

The setup just requires the execution of the compose file below:

```yaml
services:
  syncthing:
    image: syncthing/syncthing
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /your/desired/directory/Syncthing:/var/syncthing
    networks:
      home:
        ipv4_address: your.desired.address.here
      services:
        ipv4_address: your.desired.address.here

networks:
  home:
    name: home
    external: true
  services:
    name: services
    external: true
```

The `PUID` and `PGID` variables in the `environment` section are used to have the right permissions for the synchronized files both inside and outside of the container.