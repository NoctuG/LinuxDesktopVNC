# Use the official Debian image as the base image
FROM debian as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update package list
# Install required packages
# Clean APT cache to reduce image size
RUN apt update && \
    apt install -y --no-install-recommends \
        wget \
        openssl \
        xz-utils && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip noVNC
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    rm v1.4.0.tar.gz

FROM debian

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /noVNC-1.4.0 /noVNC-1.4.0

RUN apt update && \
    apt install -y --no-install-recommends \
        wine \
        qemu-kvm \
        *zenhei* \
        dbus-x11 \
        curl \
        firefox-esr \
        gnome-system-monitor \
        mate-system-monitor \
        git \
        xfce4 \
        xfce4-terminal \
        tightvncserver && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Generate a random password and set it as VNC password
RUN mkdir -p $HOME/.vnc && \
    RAND_PASSWD=$(openssl rand -base64 12) && \
    echo $RAND_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo "VNC Password: $RAND_PASSWD" > $HOME/.vnc/passwd.log

#Create startup script
RUN echo '#!/bin/bash\n\
whoami\n\
cat $HOME/.vnc/passwd.log\n\
cd\n\
su -l -c "vncserver :2000 -geometry 1360x768"\n\
cd /noVNC-1.4.0\n\
./utils/launch.sh  --vnc localhost:7900 --listen 8900' > /setup.sh && \
chmod 755 /setup.sh

#Expose port
EXPOSE 8900

# Set the command to run when the container starts
CMD ["/setup.sh"]
