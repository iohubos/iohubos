FROM debian:11.1

ENV IOHUBOS_VERSION=1.1.3
ENV SUITE=bullseye
ENV WORK=/work

ARG REGISTRY=registry
ARG CUSTOM=custom
ARG MIRROR=http://deb.debian.org/debian

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    ebtables iptables net-tools bridge-utils ifupdown \
    apt-transport-https \
    curl bc screen rsync p7zip-full \
    parted dosfstools fdisk \
    debootstrap squashfs-tools grub-pc-bin grub-efi-amd64 mtools dosfstools udev \
    && rm -rf /var/lib/apt/lists/*
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# prepare working directories
RUN mkdir -p $WORK /installer

# copy source repository
COPY . $WORK/iohubos

# build builder image
RUN $WORK/iohubos/assets/bootstrap.sh 

# clean up
RUN rm -rf $WORK

WORKDIR /installer

CMD [ "/installer/build.sh" ]
