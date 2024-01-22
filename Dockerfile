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
        ca-certificates \
        xz-utils && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip noVNC
WORKDIR /root
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    mv noVNC-1.4.0 noVNC && \
    rm v1.4.0.tar.gz

FROM debian

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/user

# Create the /home/user directory
RUN mkdir -p $HOME

# Create .Xauthority
RUN touch $HOME/.Xauthority

# Copy necessary file
COPY --from=builder /root/noVNC /noVNC
RUN ls /noVNC

# Install required packages
RUN apt update && \
    apt install -y --no-install-recommends \
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

# Generate a random password and set it as VNC password
RUN mkdir -p $HOME/.vnc && \
    RAND_PASSWD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 8) && \
    echo $RAND_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo "VNC Password: $RAND_PASSWD" > $HOME/.vnc/passwd.log

#Create startup script
RUN echo '#!/bin/bash\n\
whoami\n\
cat $HOME/.vnc/passwd.log\n\
cd $HOME\n\
vncserver :2000 -geometry 1360x768\n\
/noVNC/utils/launch.sh  --vnc localhost:7900 --listen 8900' > /setup.sh && \
chmod 755 /setup.sh

#Expose port
EXPOSE 8900

# Set the command to run when the container starts
CMD ["/setup.sh"]
