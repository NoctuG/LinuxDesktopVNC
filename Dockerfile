# Use the official Debian image as the base image
FROM debian:buster-slim as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/opt/user

# Update package list
# Install required packages
# Clean APT cache to reduce image size
RUN apt update && \
    apt install -y --no-install-recommends \
        wget \
        openssl \
        ca-certificates \
        git \
        xz-utils && \
    apt clean && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip noVNC
WORKDIR $HOME
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    mv noVNC-1.4.0 noVNC && \
    rm v1.4.0.tar.gz && \
    ls -alh $HOME/noVNC  # Add this line to list the contents of the /home/user/noVNC directory

# Cloning websockify
RUN git clone https://github.com/novnc/websockify noVNC/utils/websockify

FROM debian:buster-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/user
ENV USER=user

# Create a new user
RUN useradd -d $HOME -s /bin/bash -u 1000 $USER && \
    mkdir -p $HOME && \
    chown -R $USER:$USER $HOME

# Create .Xauthority
RUN touch $HOME/.Xauthority && chown $USER:$USER $HOME/.Xauthority

# Copy and set permissions on the setup.sh script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Copy necessary files from builder stage
COPY --from=builder --chown=$USER:$USER /opt/user/noVNC /noVNC

# Verify the contents of the /noVNC directory
RUN ls -alh /noVNC

# Install required packages
RUN apt update && \
    apt install -y --no-install-recommends \
        python3 \
        wine \
        qemu-kvm \
        ttf-wqy-zenhei \
        dbus-x11 \
        curl \
        firefox-esr \
        gnome-system-monitor \
        mate-system-monitor \
        git \
        xfce4 \
        xfce4-terminal \
        tightvncserver \
        openssl \
        xfonts-base && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Switch to the new user
USER $USER

# Create the /home/user/.vnc directory
RUN mkdir -p $HOME/.vnc && chown $USER:$USER $HOME/.vnc

# Generate a random password for user and set it as an environment variable
RUN RAND_PASSWD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12) && \
    echo $RAND_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo 'xrdb $HOME/.Xresources\nxsetroot -solid grey\nstartxfce4 &'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo "VNC Password: $RAND_PASSWD" && \
    echo "export USER_PASSWORD=$RAND_PASSWD" >> $HOME/.bashrc

# Set XFCE to use a specific common font
RUN echo "Xft.dpi: 96\nXft.antialias: true\nXft.hinting: true\nXft.rgba: rgb\nXft.hintstyle: hintslight\nXft.lcdfilter: lcddefault\nXft.autohint: 0\nXft.lcdfilter: lcdlight" > $HOME/.Xresources

# Run vncserver
RUN su - user -c "vncserver"

# Switch back to root user
USER root

# Generate a random password for root and set it as an environment variable
RUN ROOT_PASSWD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12) && \
    echo "root:$ROOT_PASSWD" | chpasswd && \
    echo "Root Password: $ROOT_PASSWD" && \
    echo "export ROOT_PASSWORD=$ROOT_PASSWD" >> $HOME/.bashrc

#Expose port
EXPOSE 8900

# Set the command to run when the container starts
CMD ["/setup.sh"]
