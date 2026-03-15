#!/bin/bash

# Color constants
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Guard: ensure .env exists before sourcing
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

# Healthcheck: wait for FastAPI to actually come up (max 15s)
echo -n "[+] Waiting for backend"
for i in $(seq 1 15); do
    if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
        echo -e "\n${GREEN}[✔] Backend is UP!${NC}"
        break
    fi
    echo -n "."
    sleep 1
    if [ "$i" -eq 15 ]; then
        echo -e "\n${RED}[✖] Backend failed to start. Check backend.log${NC}"
        exit 1
    fi
done

echo "[+] Establishing secure Cloudflare tunnel..."
nohup cloudflared tunnel --url http://127.0.0.1:8000 > tunnel.log 2>&1 &

sleep 5
URL=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' tunnel.log | head -n 1)

clear
echo "=================================================="
echo -e "${GREEN}🚀 EDGE SERVER IS ONLINE${NC}"
echo "=================================================="
if [ -z "$URL" ]; then
    echo -e "${RED}🌍 Tunnel URL not found — check internet connection${NC}"
else
    echo "🌍 Public URL: $URL"
fi
echo "👤 Username:   $API_USERNAME"
echo "=================================================="
echo "To stop: pkill -f uvicorn && pkill -f cloudflared"
