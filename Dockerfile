FROM debian:11.1

ENV IOHUBOS_VERSION=1.0.1
ENV SUITE=bullseye
ENV WORK=/work

ARG REGISTRY=registry

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    ebtables iptables net-tools bridge-utils ifupdown \
    apt-transport-https \
    curl bc screen rsync p7zip-full \
    parted dosfstools fdisk \
    debootstrap squashfs-tools grub-pc-bin grub-efi-amd64 mtools dosfstools udev \
    && rm -rf /var/lib/apt/lists/*
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# initial debootstrap
ARG MIRROR=http://deb.debian.org/debian
RUN debootstrap --variant=minbase "$SUITE" $WORK/debootstrap "$MIRROR"

# prepare working directories
RUN mkdir -p $WORK /installer

# copy source repository
COPY . $WORK/iohubos

# build live firmware
RUN mkdir -p $WORK/LIVE_BOOT
RUN cp -rp $WORK/debootstrap $WORK/LIVE_BOOT/chroot
RUN mkdir -p $WORK/LIVE_BOOT/chroot/usr/src && cp -rp $WORK/iohubos $WORK/LIVE_BOOT/chroot/usr/src/.
RUN chroot $WORK/LIVE_BOOT/chroot /usr/src/iohubos/assets/live-setup.sh
# copy builtin images
RUN mkdir -p $WORK/LIVE_BOOT/chroot/var/lib/images && cp -r $WORK/iohubos/$REGISTRY/* $WORK/LIVE_BOOT/chroot/var/lib/images/.
# clean up
RUN find $WORK/LIVE_BOOT/chroot/var/log -type f -exec cp /dev/null {} \;
RUN rm -rf $WORK/LIVE_BOOT/chroot/var/log/journal/* $WORK/LIVE_BOOT/chroot/var/log/apt/*
RUN rm -rf $WORK/LIVE_BOOT/chroot/usr/src/iohubos && cat /dev/null > $WORK/LIVE_BOOT/chroot/root/.bash_history

# package into squashfs
RUN mkdir -p $WORK/LIVE_BOOT/image/live
RUN mksquashfs $WORK/LIVE_BOOT/chroot $WORK/LIVE_BOOT/image/live/filesystem.squashfs -e boot
RUN cp -p $WORK/LIVE_BOOT/chroot/boot/vmlinuz-*     $WORK/LIVE_BOOT/image/vmlinuz
RUN cp -p $WORK/LIVE_BOOT/chroot/boot/initrd.img-*  $WORK/LIVE_BOOT/image/initrd
RUN printf "${IOHUBOS_VERSION}" >  $WORK/LIVE_BOOT/image/VERSION

# create firmware image in /installer/firmware.tgz
RUN cd $WORK/LIVE_BOOT/image && tar zcvf /installer/firmware.tgz * && cd -

# build installer
RUN mkdir -p $WORK/LIVE_USB
RUN cp -rp $WORK/debootstrap $WORK/LIVE_USB/chroot
RUN mkdir -p $WORK/LIVE_USB/chroot/usr/src && cp -rp $WORK/iohubos $WORK/LIVE_USB/chroot/usr/src/.
RUN cp /installer/firmware.tgz $WORK/LIVE_USB/chroot/.
RUN chroot $WORK/LIVE_USB/chroot /usr/src/iohubos/assets/installer-setup.sh
# clean up
RUN find $WORK/LIVE_USB/chroot/var/log -type f -exec cp /dev/null {} \;
RUN rm -rf $WORK/LIVE_USB/chroot/var/log/journal/* $WORK/LIVE_USB/chroot/var/log/apt/*
RUN rm -rf $WORK/LIVE_USB/chroot/usr/src/iohubos && cat /dev/null > $WORK/LIVE_USB/chroot/root/.bash_history

# package into squashfs
RUN mkdir -p /installer/image/live
RUN mksquashfs $WORK/LIVE_USB/chroot /installer/image/live/filesystem.squashfs -e boot
RUN cp $WORK/LIVE_USB/chroot/boot/vmlinuz-*     /installer/image/vmlinuz
RUN cp $WORK/LIVE_USB/chroot/boot/initrd.img-*  /installer/image/initrd

# move builder to /installer
RUN cp $WORK/iohubos/assets/build.sh /installer/.

RUN rm -rf $WORK

WORKDIR /installer

CMD [ "/installer/build.sh" ]
