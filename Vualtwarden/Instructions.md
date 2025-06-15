# Vaultwarden
Vaultwarden is a reimplementation of [Bitwarden](https://bitwarden.com/) written in Rust.

## The Container
### Volumes
The Docker Container has just one location where it stores permanent data, so a new volume will be created:

```shell
$ sudo docker volume create vaultwarden_data
```

### Compose file
The Docker Compose file should look as follows:

```yaml
services:
  vaultwarden:
    restart: unless-stopped
    container_name: vaultwarden
    image: vaultwarden/server:latest
    volumes:
      - vaultwarden_data:/data/
    networks:
      services:
        ipv4_address: your.desired.address.here
    env_file:
      - .env

volumes:
  vaultwarden_data:
    name: vaultwarden_data
    external: true

networks:
  services:
    name: services
    external: true
```

In the `.env` file you should place important variables, like the domain name, if signups are allowed and if emergency access is allowed:

```ini
DOMAIN="https://vaultwarden.your.domain"
SIGNUPS_ALLOWED="false"
EMERGENCY_ACCESS_ALLOWED="true"
```

The above configuration has been heavily inspired by the [Vaultwarden Documentation](https://github.com/dani-garcia/vaultwarden) and [Awesome Open Source's YouTube video](https://www.youtube.com/watch?v=mq7n_0Xs1Kg), and it was adapted to fit into the current setup by interfacing to the `services` network.