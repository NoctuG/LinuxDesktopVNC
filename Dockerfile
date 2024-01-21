# Use debian as base image
FROM debian:bullseye-slim

# Update package lists
RUN apt-get update && apt-get upgrade -y

# Set environment variables
ENV NOVNC_VERSION v1.4.0
ENV VNC_GEOMETRY 1360x768
ENV VNC_PORT 2000
ENV NOVNC_PORT 8900
ENV USER user
ENV HOME /home/$USER
ENV DISPLAY :0

# Install necessary packages
RUN apt-get install -y --no-install-recommends \
    ca-certificates \
    qemu-kvm \
    fonts-wqy-zenhei \
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
    wget \
    xfonts-base \
    xfonts-75dpi \
    nginx \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a symlink for /bin/env
RUN ln -s /usr/bin/env /bin/env

# Download and extract noVNC
RUN curl -k -sSL -o noVNC.tar.gz https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
    && tar xzf noVNC.tar.gz -C / \
    && mv /noVNC-1.4.0 /noVNC \
    && rm noVNC.tar.gz

# Download and configure novnc_proxy
RUN git clone https://github.com/novnc/noVNC.git $HOME/utils/noVNC \
    && git clone https://github.com/novnc/websockify.git $HOME/utils/websockify \
    && cp $HOME/utils/noVNC/utils/novnc_proxy $HOME/utils/novnc_proxy \
    && chmod +x $HOME/utils/novnc_proxy

# Create a non-root user
RUN useradd -m $USER && echo "$USER:$USER" | chpasswd && adduser $USER sudo

# Set up VNC
RUN mkdir -p $HOME/.vnc \
    && openssl rand -base64 32 | tr -d '\n' | vncpasswd -f > $HOME/.vnc/passwd \
    && echo '/bin/env MOZ_FAKE_NO_SANDBOX=1 dbus-launch xfce4-session' > $HOME/.vnc/xstartup \
    && touch $HOME/.Xauthority \
    && chmod 600 $HOME/.vnc/passwd \
    && chmod 755 $HOME/.vnc/xstartup \
    && chown -R $USER:$USER $HOME/.vnc \
    && chown $USER:$USER $HOME/.Xauthority
USER $USER


# Set up noVNC
USER root
RUN echo "export DISPLAY=:0" >> $HOME/.vnc/xstartup

# Expose both VNC and noVNC ports
EXPOSE $VNC_PORT $NOVNC_PORT

# Create nginx configuration to serve noVNC
COPY nginx.conf /etc/nginx/sites-available/default

# Create launch.sh to start VNC Server and noVNC on container startup
RUN echo "#!/bin/bash" > $HOME/launch.sh \
    && echo "su -l -c 'vncserver :$VNC_PORT -geometry $VNC_GEOMETRY' &" >> $HOME/launch.sh \
    && echo "$HOME/utils/novnc_proxy --vnc localhost:$VNC_PORT --web $HOME/utils/noVNC &" >> $HOME/launch.sh \
    && echo "nginx -g 'daemon off;'" >> $HOME/launch.sh \
    && chmod +x $HOME/launch.sh

# Modify CMD to run launch.sh as root
CMD ["/home/user/launch.sh"]
