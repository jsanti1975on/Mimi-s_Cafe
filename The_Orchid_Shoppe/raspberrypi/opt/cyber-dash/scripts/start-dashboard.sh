#!/bin/bash
# start-dashboard.sh
# Starts Cyber-Dashboard on 0.0.0.0/24 mgmt network

DASH_DIR="/opt/cyber-dash"
PORT=8081
LOG_FILE="$DASH_DIR/logs/dashboard.log"

cd "$DASH_DIR" || exit 1

echo "🚀 Starting Dashboard on port $PORT..."
echo "Logs at: $LOG_FILE"

# Stop any existing Python server on that port
pkill -f "http.server $PORT" 2>/dev/null

# Start new server
nohup python3 scripts/server.py >"LOG_FILE" 2>&1 &
