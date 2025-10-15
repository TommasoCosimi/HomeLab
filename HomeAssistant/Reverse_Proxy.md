# Run HomeAssistant behind Reverse Proxy
You can run HomeAssistant behind a Reverse Proxy by adding its address to the `trusted_proxies` section in the `configuration.yaml` file:
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies: your.reverse.proxy.ip
```