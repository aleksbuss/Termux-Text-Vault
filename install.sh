#!/bin/bash

# Цвета для красивого вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[+] Initializing Termux Text Vault dependencies...${NC}"
pkg update -y
pkg install python cloudflared sqlite git -y
pip install -r requirements.txt

# --- ИНТЕРАКТИВНАЯ НАСТРОЙКА БЕЗОПАСНОСТИ ---
if[ ! -f .env ]; then
    echo -e "\n${GREEN}==================================================${NC}"
    echo -e "${GREEN}🛡️  SECURITY SETUP (Local Only)${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "Your Vault will be exposed to the global internet."
    echo -e "Let's create a secure login so nobody else can access your data.\n"
    
    # Запрашиваем логин
    read -p "Enter a Username (default: admin): " set_user
    set_user=${set_user:-admin}
    
    # Запрашиваем пароль в скрытом режиме
    while true; do
        read -s -p "Enter a Password: " set_pass
        echo ""
        if [ -z "$set_pass" ]; then
            echo -e "${RED}[!] Password cannot be empty! Please try again.${NC}"
        else
            break
        fi
    done

    # Создаем локальный скрытый файл .env, который НИКОГДА не попадет на GitHub
    echo "API_USERNAME=$set_user" > .env
    echo "API_PASSWORD=$set_pass" >> .env
    echo -e "${GREEN}[✔] Credentials saved securely to local .env file.${NC}\n"
fi

echo -e "${BLUE}[✔] Deployment environment successfully provisioned! Execute: ./start.sh${NC}"
