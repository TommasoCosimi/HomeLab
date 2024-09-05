# Stirling PDF

Stirling PDF is a suite of tools to manage PDFs.

## The Container

### Volumes

The Docker Container needs four locations where it stores permanent data, so four new volumes will be created:

```shell
$ sudo docker volume create stirlingpdf_trainingData
$ sudo docker volume create stirlingpdf_extraConfigs
$ sudo docker volume create stirlingpdf_customFiles
$ sudo docker volume create stirlingpdf_logs
```

### Compose file

The Docker Compose file should look as follows:

```yaml
services:
  stirling-pdf:
    image: frooodle/s-pdf:latest
    restart: unless-stopped
    container_name: stirling-pdf
    environment:
      - DOCKER_ENABLE_SECURITY=false
      - INSTALL_BOOK_AND_ADVANCED_HTML_OPS=true
      - LANGS=it_IT
    networks:
      services:
        ipv4_address: your.desired.ip.address
    volumes:
      - stirlingpdf_trainingData:/usr/share/tessdata
      - stirlingpdf_extraConfigs:/configs
      - stirlingpdf_customFiles:/customFiles/
      - stirlingpdf_logs:/logs/

volumes:
  stirlingpdf_trainingData:
    name: stirlingpdf_trainingData
    external: true
  stirlingpdf_extraConfigs:
    name: stirlingpdf_extraConfigs
    external: true
  stirlingpdf_customFiles:
    name: stirlingpdf_customFiles
    external: true
  stirlingpdf_logs:
    name: stirlingpdf_logs
    external: true
  
networks:
  services:
    name: services
    external: true
```

The above configuration is extremely close to the default one with minor adjustments. The default configuration can be found [here](https://github.com/Stirling-Tools/Stirling-PDF).