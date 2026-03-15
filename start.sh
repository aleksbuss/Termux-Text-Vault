#!/bin/bash

# Source environment variables
set -a; source .env; set +a

echo "[+] Terminating obsolete or orphaned processes..."
pkill -f "uvicorn main:app"
pkill -f "cloudflared tunnel"
sleep 1

echo "[+] Bootstrapping the asynchronous backend server..."
nohup uvicorn main:app --host 127.0.0.1 --port 8000 > backend.log 2>&1 &

echo "[+] Establishing secure reverse tunnel via Cloudflare..."
nohup cloudflared tunnel --url http://127.0.0.1:8000 > tunnel.log 2>&1 &

sleep 5
# Extracting the dynamically allocated public URL
URL=$(grep -o 'https://[-0-9a-z]*\.trycloudflare\.com' tunnel.log | head -n 1)

clear
echo "=================================================="
echo "🚀 EDGE SERVER IS ONLINE AND OPERATIONAL"
echo "=================================================="
echo "🌍 Public Secure URL: $URL"
echo "👤 Authenticated User: $API_USERNAME"
echo "🔑 Active Password: $API_PASSWORD"
echo "=================================================="
echo "To gracefully terminate the daemon, press CTRL+C and execute:"
echo "pkill -f uvicorn && pkill -f cloudflared"
