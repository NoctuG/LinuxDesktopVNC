#!/bin/bash

# Print user and root passwords
echo "User password: $USER_PASSWORD"
echo "Root password: $ROOT_PASSWORD"

# Ensure the VNC password directory exists
mkdir -p $HOME/.vnc

# Start VNC server
vncserver :0 -geometry 1360x768 -depth 24 -localhost no &

# Start noVNC
/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8900
