# Use the official Debian image as the base image
FROM debian:bullseye as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install required packages
RUN apt install -y --no-install-recommends \
        wget \
        openssl \
        ca-certificates \
        git \
        build-essential \
        libffi-dev \
        libssl-dev \
        python3-dev \
        xz-utils

# Clean APT cache to reduce image size
RUN apt clean && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3, pip and necessary libraries
RUN apt-get update && apt-get install -y python3 python3-pip python3-dev build-essential libblas-dev liblapack-dev gfortran

# Install Python’s numpy module
RUN pip3 install numpy

# Download and unzip noVNC
WORKDIR $HOME
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    mv noVNC-1.4.0 noVNC && \
    rm v1.4.0.tar.gz && \
    ls -alh $HOME/noVNC  # Add this line to list the contents of the /root/noVNC directory

# Cloning websockify
RUN git clone https://github.com/novnc/websockify noVNC/utils/websockify

FROM debian:bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV USER=root
ENV USER_PASSWORD=password
ENV ROOT_PASSWORD=password

# Copy and set permissions on the setup.sh script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Copy necessary files from builder stage
COPY --from=builder --chown=$USER:$USER /root/noVNC /noVNC

# Verify the contents of the /noVNC directory
RUN ls -alh /noVNC

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

# Create the /root/.vnc directory
RUN mkdir -p $HOME/.vnc && chown $USER:$USER $HOME/.vnc

# Set user password for VNC and root
RUN echo $USER_PASSWORD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo 'xrdb $HOME/.Xresources\nxsetroot -solid grey\nstartxfce4 &'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo "root:$ROOT_PASSWORD" | chpasswd

# Set XFCE to use a specific common font
RUN echo "Xft.dpi: 96\nXft.antialias: true\nXft.hinting: true\nXft.rgba: rgb\nXft.hintstyle: hintslight\nXft.lcdfilter: lcddefault\nXft.autohint: 0\nXft.lcdfilter: lcdlight" > $HOME/.Xresources

#Expose port
EXPOSE 8900

# Set the command to run when the container starts
CMD ["/setup.sh"]
