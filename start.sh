#!/bin/bash

# Color constants
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Guard: ensure .env exists
if [ ! -f .env ]; then
    echo -e "${RED}[✖] .env file not found! Run ./install.sh first.${NC}"
    exit 1
fi

# Source environment variables
set -a; source .env; set +a

echo "[+] Terminating orphaned processes..."
pkill -f "uvicorn main:app" 2>/dev/null
pkill -f "cloudflared tunnel" 2>/dev/null
sleep 1

echo "[+] Bootstrapping the async backend server..."
nohup uvicorn main:app --host 127.0.0.1 --port 8000 > backend.log 2>&1 &
BACKEND_PID=$!

# Healthcheck using Python (curl may not be installed on Termux)
echo -n "[+] Waiting for backend"
for i in $(seq 1 20); do
    # Check if process is still alive
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "\n${RED}[✖] Backend process crashed. Log:${NC}"
        tail -20 backend.log
        exit 1
    fi
    # Try to connect
    if python -c "
import urllib.request
try:
    urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=2)
    exit(0)
except:
    exit(1)
" 2>/dev/null; then
        echo -e "\n${GREEN}[✔] Backend is UP! (PID: $BACKEND_PID)${NC}"
        break
    fi
    echo -n "."
    sleep 1
    if [ "$i" -eq 20 ]; then
        echo -e "\n${RED}[✖] Backend failed to start after 20s. Log:${NC}"
        tail -20 backend.log
        exit 1
    fi
done

echo "[+] Establishing secure Cloudflare tunnel..."
nohup cloudflared tunnel --url http://127.0.0.1:8000 > tunnel.log 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel URL to appear
echo -n "[+] Waiting for tunnel URL"
for i in $(seq 1 15); do
    URL=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' tunnel.log 2>/dev/null | head -n 1)
    if [ -n "$URL" ]; then
        echo ""
        break
    fi
    echo -n "."
    sleep 1
done

clear
echo "=================================================="
echo -e "${GREEN}🚀 EDGE SERVER IS ONLINE${NC}"
echo "=================================================="
if [ -z "$URL" ]; then
    echo -e "${RED}🌍 Tunnel URL not found — check internet or tunnel.log${NC}"
else
    echo "🌍 Public URL: $URL"
fi
echo "👤 Username:   $API_USERNAME"
echo "=================================================="
echo ""
echo "To stop:  pkill -f uvicorn && pkill -f cloudflared"
echo "Logs:     tail -f backend.log | tail -f tunnel.log"
