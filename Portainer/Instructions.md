# Portainer
## Data Volume
Portainer needs a place to store its data persistently. It is advisable to use Docker Volumes rather than Bind Mounts.

If you want to go deeper, refer to the [Docker Wiki](https://docs.docker.com/storage/volumes/#mount-a-host-directory-as-a-data-volume).

```shell
$ sudo docker volume create portainer_data
```

## Start the Container
Use the provided `docker-compose.yml` file to deploy Portainer.

To use the Compose file just launch the following command inside the folder where you saved it:

```shell
$ sudo docker compose up -d
```
