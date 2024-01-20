#!/bin/bash

# Start the VNC server
vncserver :1 -geometry 1360x768

# Start the desktop environment
startxfce4 &

# Start noVNC
/noVNC/utils/launch.sh --vnc localhost:5901
