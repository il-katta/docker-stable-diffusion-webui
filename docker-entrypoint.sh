#!/bin/sh
set -xe
mkdir --mode=0700 -p /run/sshd
/usr/sbin/sshd -t
/usr/sbin/sshd
if [ -n "${PUBLIC_KEY}" ]; then
    mkdir --mode 0700 -p ~/.ssh
    /usr/bin/echo -e "${PUBLIC_KEY}" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

mkdir -p /out/sd/models/Stable-diffusion
mkdir -p /out/sd/models/Lora
mkdir -p /out/sd/models/VAE
mkdir -p /out/sd/models/ESRGAN
mkdir -p /out/sd/embeddings

su appuser --command "git config --global --add safe.directory '*'"
exec su appuser --command "./webui.sh $@"
