#!/bin/bash

# Start VNC server
vncserver :0 -geometry 1360x768 -depth 24 -localhost no &

# Start noVNC
/noVNC/utils/launch.sh --vnc localhost:5900
