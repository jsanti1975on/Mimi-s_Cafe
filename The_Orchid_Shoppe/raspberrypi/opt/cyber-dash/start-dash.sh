#!/bin/bash

# =========================================
# East Side Dashboard Startup Script
# Raspberry Pi
# =========================================

APP_DIR="/home/dubz/opt"
VENV_DIR="/home/dubz/vSpring2026"
LOG_FILE="$APP_DIR/server.log"

cd "$APP_DIR" || exit 1

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Kill existing dashboard process
pkill -f "python3 server.py" 2>/dev/null

echo "Starting East Side Server..."
echo "Logging to $LOG_FILE"

# Start app
nohup python3 server.py >"$LOG_FILE" 2>&1 &
