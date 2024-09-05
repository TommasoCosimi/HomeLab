# Nginx Proxy Manager Installation

Nginx Proxy Manager will be used as a Reverse Proxy and to have the hosted services domains with working SSL Certificates.

## The Container

### Volumes

The Docker Container has two locations where it stores permanent data, so two new volumes will be created:

```shell
$ sudo docker volume create nginx-proxymanager_data
$ sudo docker volume create nginx-proxymanager_letsencrypt
```

### Compose file

The Docker Compose file should look as follows:

```yaml
services:
  nginx-proxymanager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    container_name: nginx-proxymanager
    ports:
      - 80:80
      - 443:443
      - 81:81
    networks:
      services:
        ipv4_address: your.desired.address.here
    volumes:
      - nginx-proxymanager_data:/data
      - nginx-proxymanager_letsencrypt:/etc/letsencrypt

volumes:
  nginx-proxymanager_data:
    name: nginx-proxymanager_data
    external: true
  nginx-proxymanager_letsencrypt:
    name: nginx-proxymanager_letsencrypt
    external: true

networks:
  services:
    name: services
    external: true
```

The above configuration has been heavily inspired by the [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/setup/), and it was adapted to fit into the current setup: using both an interface to the Local LAN and one to the `services` network, all while storing its permanent data inside the two previously defined volumes.