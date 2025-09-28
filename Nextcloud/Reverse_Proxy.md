# Additional configuration for Nginx Proxy Manager
## Nextcloud Container
By following the instructions in the [GitHub README of the Nextcloud official Docker container image](https://github.com/nextcloud/docker?tab=readme-ov-file#using-the-image-behind-a-reverse-proxy-and-specifying-the-server-host-and-protocol), it is possible to enable HTTPS communication between the container itself and the reverse proxy by adding the following environment variables:
```ini
APACHE_DISABLE_REWRITE_IP=1
TRUSTED_PROXIES=your.reverse.proxy.ip/netmask
```

## Proxy Host
Add these lines to the Advanced configuration of the Proxy Host to enable both usability from iOS Applications and DAV:

```
proxy_hide_header Upgrade;

location /.well-known/carddav {
    return 301 $scheme://$host/remote.php/dav;
}

location /.well-known/caldav {
    return 301 $scheme://$host/remote.php/dav;
}

location ^~ /.well-known {
    return 301 $scheme://$host/index.php$uri;
}
```
This configuration is taken from the [Nextcloud Wiki](https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/reverse_proxy_configuration.html).