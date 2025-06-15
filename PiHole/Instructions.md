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
        ipv4_address: your.desired.address.here
  pihole:
    image: pihole/pihole
    restart: unless-stopped
    container_name: pihole_webui
    env_file:
      - .env
    volumes:
      - pihole_config:/etc/pihole/
      - pihole_dnsmasq:/etc/dnsmasq.d/
    networks:
      internal:
        ipv4_address: your.desired.address.here
      home:
        ipv4_address: your.desired.address.here
      services:
        ipv4_address: your.desired.address.here
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
        - subnet: your.desired.address.here/29
  home:
    name: home
    external: true
  services:
    name: services
    external: true
```

This configuration was heavily inspired by [Michael Roach's guide](https://mroach.com/2020/08/pi-hole-and-cloudflared-with-docker/) and, as always, slightly adapted to my usecase.

Once the compose file is set up, we need to set some environment variables through the `.env` file references in the aforementioned compose file:
```ini
FTLCONF_webserver_api_password="SuperStrongPasswordThatYouDefinitelyShouldChange"
TZ="Europe/Rome"
FTLCONF_dns_upstreams="your.cloudflared.address.here#5053;9.9.9.9"
FTLCONF_dns_dnssec="true"
FTLCONF_dns_listeningMode="all"
FTL_LOG_LEVEL="warn"
```