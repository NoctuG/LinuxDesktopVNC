# Use debian as base image
FROM debian:bullseye-slim

# Set environment variables
ENV NOVNC_VERSION v1.4.0
ENV VNC_GEOMETRY 1360x768
ENV VNC_PORT 2000
ENV NOVNC_PORT 8900
ENV USER user

# Update and install necessary packages
RUN apt-get update && apt-get install -y ca-certificates
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    qemu-kvm fonts-wqy-zenhei xz-utils dbus-x11 curl firefox-esr \
    gnome-system-monitor mate-system-monitor git xfce4 \
    xfce4-terminal tightvncserver wget && \
    rm -rf /var/lib/apt/lists/*

# Install necessary fonts for VNC
RUN apt-get update && apt-get install -y xfonts-base xfonts-75dpi && \
    rm -rf /var/lib/apt/lists/*

# Create a symlink for /bin/env
RUN ln -s /usr/bin/env /bin/env

# Download and extract noVNC
RUN curl -k -sSL -o noVNC.tar.gz https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar xzf noVNC.tar.gz -C / && \
    mv /noVNC-1.4.0 /noVNC && \
    rm noVNC.tar.gz

# Create a non-root user
RUN useradd -m $USER

# Set non-root user's HOME environment variable
ENV HOME /home/$USER

# Set up VNC
RUN mkdir -p $HOME/.vnc && \
    openssl rand -base64 12 | tr -d '\n' | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    touch $HOME/.Xauthority && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    chown -R $USER:$USER $HOME/.vnc

# Switch to the non-root user
USER $USER

# Set up noVNC
RUN echo "cd /noVNC" >> $HOME/.vnc/xstartup && \
    echo $DISPLAY >> $HOME/.vnc/xstartup && \
    echo "export DISPLAY=:0" >> $HOME/.vnc/xstartup && \
    echo "./utils/launch.sh --vnc 0.0.0.0:${VNC_PORT} --listen ${NOVNC_PORT}" >> $HOME/.vnc/xstartup

# Switch back to root to set root password
USER root

# Expose the noVNC port
EXPOSE $NOVNC_PORT

# Create launch.sh to start VNC Server and noVNC on container startup
# Create launch.sh to start VNC Server and noVNC on container startup
RUN echo "#!/bin/bash" > /launch.sh && \
    echo "root_password=\$(openssl rand -base64 12)" >> /launch.sh && \
    echo "user_password=\$(openssl rand -base64 12)" >> /launch.sh && \
    echo "echo \"root:\${root_password}\" | chpasswd" >> /launch.sh && \
    echo "echo \"user:\${user_password}\" | chpasswd" >> /launch.sh && \
    echo "echo \"Root password: \${root_password}\"" >> /launch.sh && \
    echo "echo \"User password: \${user_password}\"" >> /launch.sh && \
    echo "su -c \"vncserver :$VNC_PORT -geometry $VNC_GEOMETRY\" $USER &" >> /launch.sh && \
    echo "su -c \"bash $HOME/.vnc/xstartup\" $USER &" >> /launch.sh && \
    echo "tail -f /dev/null" >> /launch.sh  # Keep the script running
RUN chmod +x /launch.sh

CMD ["/launch.sh"]
