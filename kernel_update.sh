#!/bin/bash

yum install gcc make flex bison bc openssl-devel elfutils-devel python3 perl -y
curl -o /root/linux-6.2.2.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.2.2.tar.xz
tar -xf /root/linux-6.2.2.tar.xz -C /usr/src/
cd /usr/src/linux-6.2.2/
yes "" | make oldconfig
sed -i -e 's/CONFIG_MODULE_SIG_KEY\=\".*/CONFIG_MODULE_SIG_KEY\=\"\"/g' -e 's/CONFIG_SYSTEM_TRUSTED_KEYS\=\".*/CONFIG_SYSTEM_TRUSTED_KEYS\=\"\"/g' -e 's/^CONFIG_DEBUG_INFO_BTF\=y/\# CONFIG_DEBUG_INFO_BTF is not set/g' -e 's/^CONFIG_MODULE_SIG_ALL\=y/\# CONFIG_MODULE_SIG_ALL is not set/g' .config
make
make modules_install
make install
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
