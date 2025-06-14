# Networks

I currently use two common networks for my instances:
* The `home` network is used to interface the Containers with my home LAN and is not used by all of them;
* The `services` network is instead used by all the Containers to comunicate with each other effectively;
* The `vmnet` network is used to access Virtual Machines which reside behind it, mostly for SSH and RDP purposes.

## `home`

```shell
sudo docker network create \
    -d ipvlan \
    -o parent=yourInterfaceName \
    --subnet your.home.network.subnet/mask \
    --gateway your.home.network.gatway \
    home
```

## `services`

```shell
sudo docker network create \
    -d bridge \
    --subnet your.desired.address.space \
    --gateway your.desired.gateway.address \
    services
```

## `vmnet`

```shell
sudo docker network create \
    -d ipvlan \
    -o parent=yourInterfaceName \
    --subnet your.virual_machines.network.subnet/mask \
    --gateway your.virual_machines.network.gatway \
    vmnet
```
