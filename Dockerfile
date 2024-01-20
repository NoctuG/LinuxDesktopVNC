# Use debian as base image
FROM debian

# Set environment variables
ENV NOVNC_VERSION v1.2.0
ENV VNC_PASSWD luo
ENV VNC_GEOMETRY 1360x768
ENV VNC_PORT 2000
ENV NOVNC_PORT 8900

# Add i386 architecture, update and install necessary packages
RUN dpkg --add-architecture i386 && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    wine qemu-kvm zenhei xz-utils dbus-x11 curl firefox-esr \
    gnome-system-monitor mate-system-monitor git xfce4 \
    xfce4-terminal tightvncserver wget

# Download and extract noVNC
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/${NOVNC_VERSION}.tar.gz && \
    tar -xvf ${NOVNC_VERSION}.tar.gz && \
    rm ${NOVNC_VERSION}.tar.gz

# Create a non-root user
RUN useradd -m user

# Switch to the non-root user
USER user

# Set non-root user's HOME environment variable
ENV HOME /home/user

# Set up VNC
RUN mkdir -p $HOME/.vnc && \
    echo $VNC_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup

# Set up noVNC
RUN echo "cd /noVNC-${NOVNC_VERSION}" >> $HOME/.vnc/xstartup && \
    echo "./utils/launch.sh  --vnc localhost:${VNC_PORT} --listen ${NOVNC_PORT}" >> $HOME/.vnc/xstartup

# Switch back to root to set root password
USER root
RUN echo 'root:root' | chpasswd

# Expose the noVNC port
EXPOSE $NOVNC_PORT

# Switch back to non-root user
USER user

# Start VNC Server and noVNC on container startup
CMD vncserver :$VNC_PORT -geometry $VNC_GEOMETRY && \
    bash $HOME/.vnc/xstartup
