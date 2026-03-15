#!/bin/bash

# Color constants
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[+] Initializing Termux Text Vault dependencies...${NC}"
pkg update -y
pkg install python cloudflared sqlite git -y

# --- PYDANTIC-CORE FIX FOR ANDROID/TERMUX ---
# pydantic-core is a Rust extension — PyPI has no pre-built wheels for Android.
# Strategy: use community-maintained pre-compiled wheels first, Rust compile as fallback.

# Export Android API level (required by maturin/Rust if compiling from source)
export ANDROID_API_LEVEL=$(getprop ro.build.version.sdk 2>/dev/null || echo 24)

echo -e "${BLUE}[+] Installing Python dependencies...${NC}"
echo -e "${BLUE}    (Using pre-built Android wheels for pydantic-core)${NC}"

pip install -r requirements.txt \
    --extra-index-url https://eutalix.github.io/android-pydantic-core/ 2>&1

# Check if pip install succeeded
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}[!] Pre-built wheels failed. Attempting Rust compilation (may take 10-20 min)...${NC}"
    pkg install rust binutils -y
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}[✖] Installation failed. Check errors above.${NC}"
        exit 1
    fi
fi

# Quick sanity check — can Python actually import everything?
python -c "from fastapi import FastAPI; import aiosqlite; print('All imports OK')" 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}[✖] Python import check failed. Dependencies are broken.${NC}"
    exit 1
fi

echo -e "${GREEN}[✔] All dependencies installed successfully!${NC}"

# --- INTERACTIVE SECURITY SETUP ---
if [ ! -f .env ]; then
    echo -e "\n${GREEN}==================================================${NC}"
    echo -e "${GREEN}🛡️  SECURITY SETUP (Local Only)${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "Your Vault will be exposed to the global internet."
    echo -e "Let's create a secure login so nobody else can access your data.\n"

    # Username prompt
    read -p "Enter a Username (default: admin): " set_user
    set_user=${set_user:-admin}

    # Hidden password prompt with empty check
    while true; do
        read -s -p "Enter a Password: " set_pass
        echo ""
        if [ -z "$set_pass" ]; then
            echo -e "${RED}[!] Password cannot be empty! Please try again.${NC}"
        else
            break
        fi
    done

    # Write credentials to local-only .env (protected by .gitignore)
    echo "API_USERNAME=$set_user" > .env
    echo "API_PASSWORD=$set_pass" >> .env
    echo -e "\n${GREEN}[✔] Credentials saved to local .env file.${NC}"
else
    echo -e "${GREEN}[i] Existing .env detected — skipping credential setup.${NC}"
fi

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}[✔] Installation complete! Run: ./start.sh${NC}"
echo -e "${GREEN}==================================================${NC}"
