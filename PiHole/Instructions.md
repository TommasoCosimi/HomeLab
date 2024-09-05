# PiHole

[PiHole](https://pi-hole.net/) is a local recursive DNS (but also a DHCP Server!) with Ad Blocking capabilities.

In this example I am going to use PiHole in conjunction with `Cloudflared` to have a local recursive DNS Server which will serve my DNS requests using the DoH (DNS-over-HTTPS) Protocol.

## The Container

### Volumes

The Docker Container has two locations where it stores permanent data, so two new volumes will be created:

```shell
$ sudo docker volume create pihole_config
$ sudo docker volume create pihole_dnsmasq
```

### Compose file

The compose file should look as follows:

```yml
services:
  cloudflared:
    image: cloudflare/cloudflared
    restart: unless-stopped
    container_name: pihole_cloudflared
    command: proxy-dns
    environment:
      TUNNEL_DNS_UPSTREAM: 'https://9.9.9.9/dns-query,https://149.112.112.9/dns-query,https://1.1.1.1/dns-query,https://1.0.0.1/dns-query'
      TUNNEL_DNS_PORT: '5053'
      TUNNEL_DNS_ADDRESS: '0.0.0.0'
    networks:
      internal:
        ipv4_address: cloudflared.internal.ip.address
  pihole:
    image: pihole/pihole
    restart: unless-stopped
    container_name: pihole_webui
    environment:
      TZ: 'Europe/Rome'
      WEBPASSWORD: ':CHANGEME!'
      DNS1: 'cloudflared.internal.ip.address#5053'
      DNS2: 'no'
      DNSSEC: 'true'
      QUERY_LOGGING: 'false'
      DNSMASQ_LISTENING: 'all'
    volumes:
      - pihole_config:/etc/pihole/
      - pihole_dnsmasq:/etc/dnsmasq.d/
    networks:
      internal:
        ipv4_address: your.desired.ip.address
      home:
        ipv4_address: your.desired.ip.address
      services:
        ipv4_address: your.desired.ip.address
    depends_on:
      - cloudflared

volumes:
  pihole_config:
    name: pihole_config
    external: true
  pihole_dnsmasq:
    name: pihole_dnsmasq
    external: true

networks:
  internal:
    ipam:
      config:
        - subnet: your.desired.address.space/cidr
  home:
    name: home
    external: true
  services:
    name: services
    external: true
```

This configuration was heavily inspired by [Michael Roach's guide](https://mroach.com/2020/08/pi-hole-and-cloudflared-with-docker/) and, as always, slightly adapted to my usecase.
