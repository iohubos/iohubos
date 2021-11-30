# IOhubOS

[![IOhubOS Logo](https://github.com/iohubos/iohubos/blob/media/iohubos.svg?raw=true)](https://github.com/iohubos/iohubos)

[![License](https://img.shields.io/github/license/iohubos/iohubos.svg)](LICENSE)
[![CircleCI Build Status](https://circleci.com/gh/iohubos/iohubos/tree/master.svg?style=shield)](https://circleci.com/gh/iohubos/iohubos/tree/master)

## Introduction

IOhubOS is a Linux-based distro designed for Industrial and IIoT environments,
ready to run Docker-based applications.

Its main usages are:

* data collection
* charting
* applications orchestration
* integrating field devices (PLCs, IoT, and Industrial sensors, etc.), cloud services (e.g., AWS Timestream, Azure IoT, etc.), on-premise systems/databases (e.g., InfluxDB, Grafana, MES, ERP, etc.)

Its main characteristics are:

* It is a live distro, designed to be resilient to frequent power outages, with read-only filesystems.
* It can be used offline, with no internet connection.
* It provides firmware upgrades and downgrades capabilities with no impact on installed applications.
* It can be used on edge devices, inside a control panel, or as an industrial router.
* When used as a router, it can fully isolate all the connected devices from the internet and provide a secure, isolated network.
* It provides port forwards to the connected devices when used as a router.
* It does not require any complicated configuration or system administration skills; the whole configuration is centralized in a single file.
* It provides a complete Docker-based runtime environment, with a full set of tools to deploy, run and manage applications.
* It can be extended at the firmware level or during runtime without affecting the underlying operating system.
* It provides out-of-the-box WiFi client mode when an ethernet connection is not available.
* When configured in router mode, it provides an out-of-the-box WiFi access point mode for edge devices/sensors.
* It provides SSH access through password or SSH keys.
* It provides an internal Docker registry to store and share images for fast and disconnected operations.
* It provides Docker deployment capability just copying an application to the deployment folder.
* It provides firmware upgrade/downgrade capability, just copying the firmware to the deployment folder.
* It provides an administration API to manage the Docker applications deployments.

IOhubOS is the Open Source evolution of the proprietary IOhub technology developed by [EZ VPN](https://iohubdocs.ezvpn.online/).

IOhubOS is backward compatible with the existing IOhub; existing IOhub application can be exported and deployed on IOhubOS.

While the existing IOhub technology is proprietary, it is still used in many industries and is used in a wide range of environments.

The new IOhubOS aims to become the de-facto standard operating system for Industrial and IIoT environments.

IOhubOS will eventually replace the existing IOhub installations, and the IOhubOS will be the new standard operating system for Industrial and IIoT environments.

All the Docker images created for IOhub, can be used, at no cost, in IOhubOS.

### Prerequisites

* x86_64 architecture (ARM compatibility will follow).
* 1GbByte of RAM.
* 16GByte of storage.
* One or two network adapters.

## How to install IOhubOS

1. Download the installer image from [here](https://github.com/iohubos/iohubos/releases)
2. Flash `installer.img` to a USB stick using any available tool, e.g., [`Rufus`](https://rufus.ie) on Windows, [`balenaEtcher`](https://www.balena.io/etcher/) on Windows, and macOS.
3. Boot from the USB stick.
4. Run `iohub-installer <destination disk device> [<first network adapter>]`

If you do not know the disk device, you can run the `lsblk` command to get a list of available disks. It will probably be something like `/dev/sda` or `/dev/mmcblk0`.

If you do not know the name of your network device, the installer will run an autodetect procedure using the first network adapter found with a cable connected to a network with a DHCP server. You can otherwise run the `lshw -class network -short` command to see a list of the available network interfaces

The installer will ask you for the root password to use later to configure the system.

Once IOhubOS is installed, it will ask you to press enter to shut down the system. After the system has shut down, you can remove the USB stick and boot it up again.

## First boot

Once the system is started, after a few seconds, you will see on the console a message with the name of the network interface used to connect to the network and its IP address.

**Note:** the first boot may take a while, because the whole system is set up first the first time.

To configure the system, you can either log on to the console as root or use an SSH client, using the password you provided during the installation. The SSH server is by default enabled after the first boot, allowing you to connect to the system using SSH. You can disable it later.

## How to configure IOhubOS

### `/iohub/envvars`

You can configure almost every IOhubOS behavior just by editing the `/iohub/envvars` file.

You can change the configuration using one of the available editors installed, `vi` and `nano`.

Once you change the configuration, you must reboot the system to apply the changes.

#### SSH server

You can enable/disable the SSH server by setting the `IOHUBOS_OPENSSH_ENABLED` variable to `true/false`.

If you want to access the system using an SSH key, set the public key in the `IOHUBOS_SSH_PUBLIC_KEY` variable.

#### Network configuration

You can configure the IOhubOS networking in two ways:

* `standalone mode`
* `router mode`

The variable `IOHUBOS_NETWORK_MODE` can be set to `standalone` or `router`.

##### Standalone mode

Only one network interface is used, identified in the configuration as ETH0 (ETH0 is not the real device name, it is meant as an identifier for the main interface).

The network interface can be configured in DHCP or static mode, configuring the variables below:

```bash
IOHUBOS_ETH0_MODE='dhcp'                    # dhcp/static
IOHUBOS_ETH0_IP=''                          # e.g. 192.168.190.254
IOHUBOS_ETH0_NETMASK=''                     # e.g. 255.255.255.0
IOHUBOS_ETH0_GATEWAY=''                     # e.g. 192.168.190.1
IOHUBOS_ETH0_DNS=''                         # space separated list, e.g. 192.168.190.1 8.8.8.8
```

##### Router mode

Two interfaces are used, identified in the configuration as ETH0 and ETH1 (ETH0/ETH1 are not the real device names, they are meant as identifiers for the main and secondary interface).

ETH0 is used as the main interface, connected to the local LAN, and ETH1 is used as the secondary interface, where the devices/sensors are connected.

ETH0 can be configured as in the standalone mode. ETH1 can be configured only with a static IP address, configuring the variables below:

```bash
IOHUBOS_ETH1_DEVICE=''                      # e.g. enp1s0
IOHUBOS_ETH1_IP=''                          # e.g. 10.11.12.13
IOHUBOS_ETH1_NETMASK=''                     # e.g. 255.255.255.0
```

If you do now know the name of the ETH1 network device, you can run the `lshw -class network -short` command to get a list of available network devices.

#### DHCP server

When router mode is configured, you can enable a DHCP server for the ETH1 network. The DHCP server can be configured using the variables below:

```bash
IOHUBOS_DHCP_SERVER_ENABLED='false'         # dhcp server on eth1
IOHUBOS_DHCP_SERVER_FROM=''                 # e.g. 10.11.12.100
IOHUBOS_DHCP_SERVER_TO=''                   # e.g. 10.11.12.199
IOHUBOS_DHCP_SERVER_DNS=''                  # comma separated list, e.g. 192.168.190.1, 8.8.8.8
```

#### WiFi client mode

If you have available a WiFi interface, you can enable WiFi client mode. When enabled, the system will try to connect to the WiFi network, using the SSID and WPA password provided in the configuration (only WPA/WPA2 connections are compatible).

When the Wifi client mode is enabled, the cabled main interface is disabled. Any feature configured for ETH0 will be used applied to the WiFi interface.

You can enable Wifi client mode by setting the `IOHUBOS_WIFI_MODE` variable to `client` and configuring the WPA SSID and password in the `IOHUBOS_WIFI_CLIENT_SSID` and `IOHUBOS_WIFI_CLIENT_PASS` variables.

```bash
IOHUBOS_WIFI_MODE='client'
IOHUBOS_WIFI_DEVICE=''                      # wifi interface. 'auto' for autodiscovery
IOHUBOS_WIFI_CLIENT_SSID=''                 # wifi client ssid
IOHUBOS_WIFI_CLIENT_PASS=''                 # wifi client password
```

If you do not know the name of the WiFi network device, you can run `lshw -class network -short` to get a list of available network devices or use `auto` to autodetect the WiFi interface (if you have multiple WiFi interfaces, no detection ordering is guaranteed).

#### WiFi AP mode

If you have available a WiFi interface, you can enable WiFi Access Point mode. The AP mode is available only in `router` mode. The AP is bound to the ETH1 network interface.

Usually, you want to have a DHCP server available for the devices connecting to the AP.

You can enable the WiFi AP mode by setting the `IOHUBOS_WIFI_MODE` variable to `ap` and configuring the WPA SSID and password in the `IOHUBOS_WIFI_AP_SSID` and `IOHUBOS_WIFI_AP_PASS` variables.

```bash
IOHUBOS_WIFI_MODE='ap'
IOHUBOS_WIFI_DEVICE=''                      # wifi interface. 'auto' for autodiscovery
IOHUBOS_WIFI_AP_SSID=''                     # wifi ap ssid
IOHUBOS_WIFI_AP_PASS=''                     # wifi ap password
```

Suppose you do not know the name of the WiFi network device. In that case, you can run `lshw -class network -short` to get a list of available network devices or use `auto` to autodetect the WiFi interface (if you have multiple WiFi interfaces, no detection ordering is guaranteed).

#### Router network isolation

Setting the variable `IOHUBOS_FIREWALL_ROUTER_TO_INTERNET` to `false`, the devices connected to the ETH1 network will not have any access to the LAN on ETH0 and therefore to the internet. You might want to use this mode if you have industrial devices to keep safe from the internet.

Setting the variable `IOHUBOS_FIREWALL_ROUTER_TO_INTERNET` to `true`, the devices connected to the ETH1 will have standard access to the LAN on ETH0 and therefore to the internet.

#### Timezone configuration

You can change the timezone of your IOhubOS instance by changing the value of the `IOHUBOS_TIMEZONE` variable, using a value from the tz database.

#### Firmware upgrades/downgrades

You can upgrade/downgrade the running firmware of your IOhubOS instance by copying a `firmware.tgz` file to the `/iohub/firmware` directory of your IOhubOS instance and rebooting the system.

You can disable the auto-upgrade/downgrade capability by setting the `IOHUBOS_UPGRADER_ENABLED` variable to `false`.

#### Docker engine

By setting the variable `IOHUBOS_DOCKER_ENABLED` to `true`, all the Docker functionalities described below are enabled. All the enabled user applications will be started upon boot.

#### Docker applications deployment

You can deploy Docker applications running in your IOhubOS instance by copying the packaged application to the `/iohub/deploy` directory of your IOhubOS instance and rebooting the system.

You can disable the auto-deploy capability by setting the `IOHUBOS_DEPLOYER_ENABLED` variable to `false`.

The format/content of the deployable package is described in the [Docker application deployment documentation](#deploy-docker-applications).

#### Internal Docker registry

By setting `IOHUBOS_DOCKER_REGISTRY_ENABLED` to `true`, an internal Docker registry will run on the IOhubOS instance. You can use it to allow the device to keep working even when internet access is not available, have a faster startup of applications, and minimize network traffic

The Docker images embedded in the firmware are by default already available in the registry. To add new images to the registry, read the [Docker registry](#docker-registry) section below.

You can expose the internal Docker registry on ETH0 or ETH1 by setting to `true` the variables `IOHUBOS_DOCKER_REGISTRY_EXPOSE_ETH0` and `IOHUBOS_DOCKER_REGISTRY_EXPOSE_ETH1`.

#### Admin API

You can enable an administration API. The Admin API allows you to manage the installed Docker applications, as fully described [`here`](https://github.com/iohubos/iohubos-admin-api).

The Admin API is disabled by default. You need to set a strong password, in the variable `IOHUBOS_ADMIN_API_AUTH_TOKEN`, for the Admin API access. If the password is not strong enough, the Admin API will be disabled, and any call will give you a message asking to set a stronger password.

The admin API will be available at the port defined in the variable `IOHUBOS_ADMIN_API_SERVER_PORT`.

The full API in OpenAPI 3.0 format is documented [`here`](https://app.swaggerhub.com/apis-docs/iohubos/iohubos-admin-api/).

```bash
IOHUBOS_ADMIN_API_ENABLED='false'           # enable admin API
IOHUBOS_ADMIN_API_SERVER_PORT='9999'        # http port
IOHUBOS_ADMIN_API_AUTH_TOKEN=''             # header auth token
```

Please note that the Admin API gives full access to the existing Docker instances and can be used to manage the Docker instances. **Turn it on only if needed.**

### `forwards-tcp`

When in router mode, you can define TCP port forwards in the `/iohub/forwards-tcp` file.

Each line of the file, not starting with a `#`, is a forward definition.

The format of the forward definition is:

```bash
SRC_PORT=DST_IP:DST_PORT
```

where:

* `SRC_PORT` is the exposed port on ETH0
* `DST_IP` is the IP of the device to forward to
* `DST_PORT` is the port on the device to forward to

If a forward definition collides with an exposed TCP port (SSH, Docker registry, ...), the forward will be ignored.

### `forwards-udp`

When in router mode, you can define UDP port forwards in the `/iohub/forwards-udp` file.

Each line of the file, not starting with a `#`, is a forward definition.

The format of the forward definition is:

```bash
SRC_PORT=DST_IP:DST_PORT
```

where:

* `SRC_PORT` is the exposed port on ETH0
* `DST_IP` is the IP of the device to forward to
* `DST_PORT` is the port on the device to forward to

### Docker Registry

The Docker registry is enabled by default. You can disable it by setting the variable `IOHUBOS_DOCKER_REGISTRY_ENABLED` to `false`.

You can add new images to the registry by:

* setting to `true` the variable `IOHUBOS_DOCKER_REGISTRY_RESCAN`
* copying a Docker image to the `/iohub/runtime/iohub-registry` directory of your IOhubOS instance and rebooting the system.

When `IOHUBOS_DOCKER_REGISTRY_RESCAN` is `true`, the folder `/iohub/runtime/iohub-registry` will be scanned for new images and added to the registry.

if `IOHUBOS_DOCKER_REGISTRY_RESCAN_DELETE` is 'true', the image file is deleted, once imported to the registry.

#### Prepare the Docker images

Below is the procedure to create the Docker images for the automatic upload to the registry.

```bash
docker pull <docker image name>
docker save <docker image name> | gzip > <somename>.tar.gz
```

For example. to import the image mysql:5.7.36 from Docker Hub into the internal registry, you can do:

```bash
docker pull mysql:5.7.36
docker save mysql | gzip > mysql.tar.gz
```

Once you have created the gzipped files containing the images, you can copy them to the `/iohub/runtime/iohub-registry` directory of your IOhubOS instance and reboot the system.

**Note:** the name of the gzipped file is not relevant. However the extension must be `.tar.gz`.

### Deploy Docker applications

Upon reboot, the folder `/iohub/docker/apps` is scanned for Docker execution.

Any folder below `/iohub/docker/apps` represent a Docker application, whose name is the folder name. The folder name must be a valid Docker Compose application name; the format accepted is 1 to 64 characters long, starting with a lowercase letter, followed by any number of lowercase letters, numbers, hyphens, or underscores.

one file must be present in the folder `/iohub/docker/apps/<app_name>`:

* `start.sh`: the script to run when the application is started

If `start.sh` is present and has mode 755, the application will start upon boot.
Otherwise, the application will be ignored.

#### Example 1: basic

`start.sh`

```bash
#!/bin/sh
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

#### Example 2: docker-compose - IOhub compatible

`start.sh`

```bash
#!/bin/sh
[ -d /iohub/docker/apps/<app name>/volumes/app-vol ] || mkdir -p /iohub/docker/apps/<app name>/volumes/app-vol
[ -d /iohub/docker/apps/<app name>/volumes/ezvpn-grafana-vol-3 ] || mkdir -p /iohub/docker/apps/<app name>/volumes/ezvpn-grafana-vol-3
[ -d /iohub/docker/apps/<app name>/volumes/ezvpn-influxdb-vol-1 ] || mkdir -p /iohub/docker/apps/<app name>/volumes/ezvpn-influxdb-vol-1
docker-compose -f /iohub/docker/apps/<app name>/docker-compose.yml up -d
```

`docker-compose.yml`

```yaml
version: "3.8"

services:
    ezvpn-grafana:
        image: us-central1-docker.pkg.dev/ez-shared/iohub/iohub-grafana
        environment:
            INFLUXDB_HOST: "ezvpn-influxdb"
            GF_LOG_MODE: "console"
            GF_LOG_LEVEL: "error"
        ports:
            - 3000:3000
        depends_on:
            - ezvpn-influxdb
        volumes:
            - ezvpn-grafana-vol-3:/var/lib/grafana
        networks:
            - <app name>-net

    ezvpn-influxdb:
        image: us-central1-docker.pkg.dev/ez-shared/iohub/iohub-influxdb-v1
        environment:
            INFLUXDB_DATA_QUERY_LOG_ENABLED: "false"
            INFLUXDB_DB: "data"
            INFLUXDB_HTTP_LOG_ENABLED: "false"
            INFLUXDB_RP: "180d"
            INFLUXDB_REPORTING_DISABLED: "true"
        expose:
            - 8086
        volumes:
            - ezvpn-influxdb-vol-1:/var/lib/influxdb
        networks:
            - <app name>-net

    ezvpn-mqtt:
        image: us-central1-docker.pkg.dev/ez-shared/iohub/iohub-mqtt
        restart: "no"
        expose:
            - 1883
        networks:
            - <app name>-net

    ezvpn-mqtt-influxdb:
        image: us-central1-docker.pkg.dev/ez-shared/iohub/iohub-mqtt-influxdb
        restart: "no"
        environment:
            MQTT_HOST: "ezvpn-mqtt"
            INFLUXDB_HOST: "ezvpn-influxdb"
        depends_on:
            - ezvpn-mqtt
            - ezvpn-influxdb
        networks:
            - <app name>-net

volumes:
    ezvpn-grafana-vol-3:
        driver: local
        driver_opts:
            type: none
            device: /iohub/docker/apps/<app name>/volumes/ezvpn-grafana-vol-3
            o: bind
    ezvpn-influxdb-vol-1:
        driver: local
        driver_opts:
            type: none
            device: /iohub/docker/apps/<app name>/volumes/ezvpn-influxdb-vol-1
            o: bind
    app-vol:
        driver: local
        driver_opts:
            type: none
            device: /iohub/docker/apps/<app name>/volumes/app-vol
            o: bind
    global-vol:
        driver: local
        driver_opts:
            type: none
            device: /iohub/docker/global/volumes/global-vol
            o: bind

networks:
    <app name>-net:
```

**Note**: when uploading a Docker Compose file through the Admin API, a `start.sh` file is generated automatically.

You can package your Docker application definition in a zip file and upload it to the `/iohub/deploy` folder to have it deployed on the next reboot.

The structure of the zip file is described below:

```text
docker
   |--> apps
   |   |--> <app 1 name>
   |   |   |--> docker-compose.yml
   |   |   |--> start.sh
   |   |--> <app 2 name>
   |   |   |--> docker-compose.yml
   |   |   |--> start.sh
   |   |--> <app 3 name>
   |   |   |--> docker-compose.yml
   |   |   |--> start.sh
```

#### Create a zipped Docker definition file

A GUI composer application is in the roadmap. Meanwhile, if you do not want to create a zipped file manually, you can use the [EZ VPN management site](https://management.ezvpn.online) for free to create a zipped file.
You create a Development IOhub instance, design your applications and download the production zip file. You can save the downloaded file in the `/iohub/deploy` folder with no modification.

### IOhub compatibility layer

The applications created with EZ VPN IOhub are compatible with the IOhubOS. If an IOhub application is using the global MQTT broker, the following variables are available:

```bash
IOHUBOS_GLOBAL_MQTT='true'
IOHUBOS_GLOBAL_MQTT_IMG="${IOHUBOS_HOSTNAME}:5000/iohubos/iohubos-mqtt"
IOHUBOS_GLOBAL_MQTT_NAME="ezvpn-global-mqtt"
IOHUBOS_GLOBAL_MQTT_NET="ezvpn-global-mqtt-net"
```

If `IOHUBOS_GLOBAL_MQTT` is `true`, a global MQTT broker is started at boot. The default values of the remaining variables are compatible with the old IOhub applications.

If you are not using IOhub, you can change those values at your convenience, without using the `ezvpn` prefix.

## Read-only File System

IOhubOS is based on a SquashFS read-only file system.

However, it is designed to be customized by the user.

Upon each reboot, the content of the `/iohub/live` folder is copied over `/` in a volatile overlay file system, mounted over the SquashFS read-only file system. You can therefore override or extend functionalities implemented in the base distro, even if the base distro in written in a read-only file system.

**Note**: the overlay file system is hosted in RAM. Do not copy huge files to the `/iohub/live` folder because they will be copied to the RAM.

### IOhubOS Lifecycle

The IOhubOS firmware does not include any default configuration. The network is disabled; no firewall is configured; no default route is set; no DHCP server is available; no SSH server is running, no default DNS is set, etc.

Upon reboot, the service `iohub-bootstrap.service` is started.

`iohub-bootstrap` is the heart of the IOhubOS firmware. It defines the lifecycle of all the services defined above and of user/customizable services.

Below is defined the full lifecycle of the IOhubOS firmware, as defined by the `iohub-bootstrap` service (see the section [File System Structure](#file-system-structure) for a deeper understanding of the IOhubOS structure).

1. the writable partition is mounted on `/iohub`
2. `/iohub/runtime/iohub-bootstrap/postmount` is executed
3. `/iohub/runtime/iohub-bootstrap/presetup` is executed
4. if `/iohub/setup.done` is missing, the `/iohub` folder is initialized creating the needed folders and files and `/iohub/setup.done` is created
5. `/iohub/runtime/iohub-bootstrap/postsetup` is executed
6. if `/iohub/ask.noboot` is not present:
    1. `/iohub/runtime/iohub-bootstrap/prelivesync` is executed
    2. if `/iohub/disable.livesync` is not present:
        1. copy `/iohub/live/` over `/`
    3. `/iohub/runtime/iohub-bootstrap/postlivesync` is executed
    4. `/iohub/runtime/iohub-bootstrap/preliveactions` is executed
    5. if `/iohub/disable.actions` is not present:
        1. for each file in `/usr/bin/iohub-actions.d`:
            1. if the file is executable, execute it as sub command
            2. if the file is not executable, execute its content
    6. `/iohub/runtime/iohub-bootstrap/postliveactions` is executed
7. `/iohub/runtime/iohub-bootstrap/end` is executed

#### Actions

Each service is implemented by one or more scripts in the `/usr/bin/iohub-actions.d` folder.

You can disable some of the services by setting to false a specific variable.
For example, you can override the predefined networking definition setting to `false` the variable `IOHUBOS_NETWORK_CONFIG`.

You can then create your custom network configuration creating a file named like `/iohub/live/usr/bin/iohub-actions.d/0200-my-custom-network.sh` containing your custom network configuration.

Upon reboot, your script `0200-my-custom-network.sh` will be temporarily saved in the `/usr/bin/iohub-actions.d` folder and executed by the `iohub-bootstrap` service.

Please note that the script's name defines the execution order with respect to the other scripts in the `/usr/bin/iohub-actions.d` folder.

By creating custom actions, you can extend the behavior of IOhubOS as you like, applying temporary modifications to the read-only file system.

At every reboot, the actions will be re-played on the SquashFS file system.

#### iohub-bootstrap hooks

The `postmount`, `presetup`, etc. scripts are hooks that can customize the service behavior, implement even more dynamic actions, and potentially alter the lifecycle.

You might dynamically alter variable values, changing the behavior of the scripts in `/usr/bin/iohub-actions.d`.

## File System Structure

During the installation, the destination disk device is partitioned in the following way:

* partition 1: contains the GRUB bootloader
* partition 2: contains the IOhubOS read-only file system
* partition 3: contains the IOhubOS read-only file system
* partition 4: contains a writable partition, mapped on `/iohub`

After the initial installation, the GRUB bootloader points to the second partition as the default boot device.

When a new firmware is installed, it gets installed in the third partition. Upon successful installation, the GRUB bootloader is then updated to point to the third partition, and the system is rebooted.

In such a way, using the GRUB boot menu, you can boot from the previous firmware, still present in the second partition.

When a new firmware is installed, the GRUB bootloader is updated again to point to the second partition, in a round robin fashion.

Using this technique, you can boot from the previous firmware or the new firmware and run upgrades/downgrades when needed.

The fourth partition is the writable partition. It is used to store any user data, or custom configuration/behavior:

* to override the default behavior of IOhubOS
* to store the Docker Applications and their volumes/databases
* to store the IOhubOS configuration, used both by partitions 2 and 3
* to store the Docker registry
* etc.

### Main folders and files

```text
/-->                                   # read only file system
   |--> iohubos/                       # writable partition
   |   |--> deploy/                    # folder for automatic apps deployment
   |   |--> docker/                    # folder for Docker Applications
   |   |   |--> apps/                  # user applications
   |   |   |   |--> <app 1>
   |   |   |   |--> <app 2>
   |   |   |   |--> <app 3>
   |   |   |--> global/                # global applications
   |   |   |--> registry/              # internal Docker registry
   |   |--> envvars                    # user environment variables
   |   |--> envvars.d/                 # user environment variables - firmware version specific
   |   |--> firmware/                  # folder for automatic firmware deployment
   |   |--> forwards-tcp               # tcp forwards definitions
   |   |--> forwards-udp               # udp forwards definitions
   |   |--> live/                      # folder for live configuration. copied over / at boot
   |   |--> runtime/                   # folder for permanent data used by scripts
   |   |   |--> iohub-bootstrap/       # hooks definitions for iohub-boostrap
   |   |   |--> iohub-registry         # folder for Docker registry automatic import
   |   |--> sysvars                    # system environment variables
   |--> usr
   |   |--> bin
   |   |   |--> iohub-actions.d        # folder for iohub-bootstrap scripts (read only)
```

### Commands reference

* `iohub-install-firmware`: it can be used to install a new firmware manually on the next partition (partition 3 when partition 2 is the default, partition 2 otherwise).
* `iohub-next-partition`: it returns the partition number, not in use (1 or 2, for partitions 2 and 3).
* `iohub-set-boot-default`: Set the default boot partition. Optionally change the entry menu description.

## IOhubOS extension example: Logging to GCP

As an example of how it is possible to modify the IOhubOS behavior, we will adjust the default Docker logging behavior, enabling logging to GCP.

Based on the Docker instructions to implement the logging to GCP [here](https://docs.docker.com/config/containers/logging/gcplogs/),
we create three files below the `/iohub/live` folder to have them copied over their correct location upon boot.

1. `/iohub/live/etc/docker/daemon.json`: the Docker logging configuration file.
2. `/iohub/live/etc/docker/googlecloud-serviceaccount.json`: the GCP credentials file.
3. `/iohub/live/etc/systemd/system/diocker.service.d/gcplogging.conf`: the environment variable definition, to provide Docker the GCP credentials.

daemon.json

```json
{
  "log-driver": "gcplogs",
  "log-opts": {
    "gcp-project": "<your GCP project>",
    "mode": "non-blocking",
    "max-buffer-size": "50m"
  }
}

```

googlecloud-serviceaccount.json (generated on GCP, data hidden here)

```json
{
  "type": "service_account",
  "project_id": "<your GCP project>",
  "private_key_id": "<...>",
  "private_key": "-----BEGIN PRIVATE KEY-----\n<...>\n-----END PRIVATE KEY-----\n",
  "client_email": "<...>",
  "client_id": "<...>",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/<...>"
}
```

gcplogging.conf

```text
[Service]
Environment="GOOGLE_APPLICATION_CREDENTIALS=/etc/docker/googlecloud-serviceaccount.json"
```

Reboot the system to apply the changes. Your Docker engine should now be logging to GCP.

## License

IOhubOS is distributed under the terms of The GNU Affero General Public License v3.0.

See [LICENSE](LICENSE) for details.

SPDX-License-Identifier: AGPL-3.0-only

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
