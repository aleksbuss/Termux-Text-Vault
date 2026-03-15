#!/bin/bash
echo "[+] Initializing Termux Text Vault dependencies..."
pkg update -y
pkg install python cloudflared sqlite git -y
pip install -r requirements.txt

# Provisioning the environment variables configuration file
if [ ! -f .env ]; then
    echo "API_USERNAME=admin" > .env
    echo "API_PASSWORD=secret" >> .env
    echo "[!] .env configuration file generated. CRITICAL: Modify the default credentials using: nano .env"
fi

echo "[✔] Deployment environment successfully provisioned! Execute: ./start.sh"
