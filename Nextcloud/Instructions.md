# Nextcloud

## The Container

### Volumes

The Mastercontainer needs a volume to store permanent data, but this time I will let the Compose file create it.

### Compose file

The below Compose file comes from the [GitHub Repo of the Nextcloud-AIO Project](https://github.com/nextcloud/all-in-one) and has been slightly modified to account for my usage.

The real edits made are in the `environment` section:
* `APACHE_PORT` indicates the port which the Reverse Proxy (in my case Nginx Proxy Manager) has to access to talk to the Apache container inside the `nextcloud-aio` network (see the `NoteOnNextcloud` document in Nginx Proxy Manager for more info);
* `APACHE_IP_BINDING` has been set to the Nginx Proxy Manager Address for the `nextcloud-aio` network;
* `NEXTCLOUD_DATADIR` has instead been set to the folder which should contain the Nextcloud user's files (note that it can also be a volume).

The last should never be changed once the Nextcloud instance has been set up the first time.

```yml
services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    init: true
    restart: unless-stopped
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      services:
        ipv4_address: your.ip.address.here
    environment:
      APACHE_PORT: 11000
      APACHE_IP_BINDING: nginx.proxy.manager.address
      NEXTCLOUD_DATADIR: /your/desired/directory/Nextcloud

volumes:
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer

networks:
  services:
    name: services
    external: true  
```

## Setup

To set up your instance access the Nextcloud-AIO Web Interface with the IP specified in the `services` network and follow the On-Screen instructions.