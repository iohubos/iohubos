# Build IOhubOS from scratch

If you prefer building the distro instead of installing it from the official repository, you can follow the steps below.

## Build procedure

The building system has been packaged into a Docker image to make it independent on the OS you are building on (**on Windows, run the command below in PowerShell**).

You need a Docker engine installed on your pc to build the distro.

The building process will take ~10/20 minutes, depending on your network and hardware speed.

At the end of the process, you will have two files in a folder on your pc

* `installer.img`: the image that can be used to install IOhubOS from scratch.
* `firmware.tgz`: the firmware that can be used to upgrade/downgrade an existing IOhubOS.

```bash
# clone the repository
git clone git@github.com:ez-vpn/iohubos.git
cd iohubos

# download the images to embed in the distro
mkdir registry
docker run -it --privileged --rm \
    -v ${PWD}/registry:/dist \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --mount type=bind,source=${PWD}/assets/img_downloader.sh,target=/img_downloader.sh \
    --mount type=bind,source=${PWD}/assets/registry,target=/registry \
    docker /img_downloader.sh

# build the builder image
docker build --no-cache -t iohubosbuilder .

# create the destination folder for the image and the firmware
mkdir dist
docker run -it --privileged --rm -v ${PWD}/dist:/dist iohubosbuilder
```

As long the `iohubosbuilder` image is available, you can generate the installer and the firmware on need, just repeating the last step (`docker run -it --privileged --rm -v ${PWD}/dist:/dist iohubosbuilder`).

### Additional build parameters

If you want to improve the download speed while building the image, you can force a Debian mirror, for example:

```bash
docker build --no-cache --build-arg MIRROR=http://ftp.de.debian.org/debian/ -t iohubosbuilder .
```

The default value for the `MIRROR` arg is `http://deb.debian.org/debian`

You can change the `registry` folder used below passing a `build-arg REGISTRY` to the image builder:

```bash
mkdir somefolder
docker run -it --privileged --rm \
    -v ${PWD}/somefolder:/dist \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --mount type=bind,source=${PWD}/assets/img_downloader.sh,target=/img_downloader.sh \
    --mount type=bind,source=${PWD}/assets/registry,target=/registry \
    docker /img_downloader.sh
docker build --no-cache --build-arg REGISTRY=somefolder -t iohubosbuilder .
```

### Clean up

You can delete the Docker image if you want to reclaim the taken space (~5Gb).

```bash
docker image rm iohubosbuilder
```

## Flash the installer to a USB stick

You can flash the `installer.img` file to a USB stick using any available tool, e.g., [`Rufus`](https://rufus.ie) on Windows, [`balenaEtcher`](https://www.balena.io/etcher/) on Windows, and macOS.

## Customize the base distro

### Change default configuration

If you need to build the distro with different default values, you can edit the `assets/envvars` file before building the image.

You might, for example, configure IOhub as a router, assign a static IP, change the timezone, grant internet access to the devices behind the router, and so on.

### Add packages

If you need to build a customized version of IOhubOS, e.g., adding packages, you can do so by editing the `assets/live-setup-custom.include` file, before building the image.

`assets/live-setup-custom.include` is executed as the last step of the building procedure.

You can add repositories, packages, remove packages, change any default configuration, etc., to have it included in the distro.

For example, if you want to include the `nmap` package in the distro, you can add the following line to the `assets/live-setup-custom.include` file:

```bash
DEBIAN_FRONTEND=noninteractive apt-get install -y nmap
```

### Add custom firmware / modules

If you need to add custom firmware/modules to your distro (e.g. network drivers, wifi drivers, video drivers, etc.), you can do so by:

* Copy the custom firmwares/modules to the `/iohub/live/lib/firmware/` folder
* Create a `/iohub/live/usr/bin/iohub-actions.d/0050-load-custom-firmware.sh` file with the following content:

```bash
#!/bin/bash
modprobe <your module 1>
modprobe <your module 2>
# e.g. modprobe iwlwifi
```

The name of the file (`0050-load-custom-firmware.sh`) is arbitrary, but it must be a valid bash script in one of the two below formats:

* with permission 0755 and a shebang
* with permission 0644 without the shebang

The file's name determines the execution order of the scripts in the folder `/usr/bin/iohub-actions.d`. Its name should have an ordering such that it precedes all the other scripts depending on the module.

### Embed additional Docker images

If you need to embed additional Docker images in the firmware, and therefore available even when disconnected from the internet, you can do so by adding an image per line to the `assets/registry`, e.g.:

```bash
mysql:5.7
grafana/grafana:latest
postgres
```

Each of the image will be downloaded embedded in the firmware and, on first boot, automatically deployed to the local Docker registry.

## Disclaimer

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
