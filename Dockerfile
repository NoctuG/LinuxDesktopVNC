# syntax=docker/dockerfile:1
FROM debian:slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qemu-kvm \
    xz-utils \
    dbus-x11 \
    curl \
    firefox-esr \
    gnome-system-monitor \
    mate-system-monitor \
    git \
    xfce4 \
    xfce4-terminal \
    tightvncserver \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Download proot and noVNC
RUN curl -LO https://proot.gitlab.io/proot/bin/proot && \
    chmod 755 proot && \
    mv proot /bin && \
    wget https://github.com/novnc/noVNC/archive/refs/tags/v1.2.0.tar.gz && \
    tar -xvf v1.2.0.tar.gz && \
    rm v1.2.0.tar.gz

# Set up VNC password
RUN mkdir $HOME/.vnc && \
    echo 'luo' | vncpasswd -f > $HOME/.vnc/passwd && \
    chmod 600 $HOME/.vnc/passwd

# Create script to run VNC server and noVNC
RUN echo '#!/bin/bash' >>/luo.sh && \
    echo 'whoami ' >>/luo.sh && \
    echo 'cd ' >>/luo.sh && \
    echo "su -l -c  'vncserver :2000 -geometry 1280x800' "  >>/luo.sh && \
    echo 'cd /noVNC-1.2.0' >>/luo.sh && \
    echo './utils/launch.sh  --vnc localhost:7900 --listen 8900 ' >>/luo.sh && \
    chmod 755 /luo.sh

EXPOSE 8900

CMD  /luo.sh
