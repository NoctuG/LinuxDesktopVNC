#!/bin/bash

# Print user and root passwords
echo "User password: $USER_PASSWORD"
echo "Root password: $ROOT_PASSWORD"

# Ensure the VNC password directory exists
mkdir -p $HOME/.vnc

# Set the user password for VNC
echo $USER_PASSWORD | vncpasswd -f > $HOME/.vnc/passwd
chmod 600 $HOME/.vnc/passwd

# Start VNC server
vncserver :0 -geometry 1360x768 -depth 24

# Start noVNC
/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8900
