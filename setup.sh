#!/bin/bash

# Ensure the VNC password directory exists (remove if done in Dockerfile)
mkdir -p $HOME/.vnc

# Set the VNC password if not already set (remove if done in Dockerfile)
echo $USER_PASSWORD | vncpasswd -f > $HOME/.vnc/passwd
chmod 600 $HOME/.vnc/passwd

# Start VNC server in the background
vncserver :0 -geometry 1360x768 -depth 24 &

# Wait for VNC server to start
until nc -z localhost 5900; do
    echo "Waiting for VNC server to start..."
    sleep 1
done

# Start noVNC proxy in the background
/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8900 &

# If you need to wait for noVNC to start, add a similar wait loop

# Keep the script running to keep the container alive
tail -f /dev/null
