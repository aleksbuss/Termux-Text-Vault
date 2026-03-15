# 📦 Termux Text Vault (Self-Hosted Edge Storage)

**Termux Text Vault** is a lightweight, asynchronous edge-storage micro-service engineered specifically for Android devices utilizing the Termux environment. It provides a secure, self-hosted mechanism for transmitting and persisting extensive text payloads (e.g., 10MB+ datasets, logs, or books) across isolated networks without relying on physical media (USB drives) or third-party cloud brokers.

## 🔬 Architectural Overview

Designed with a minimalist "flat" structure, the system leverages a high-performance asynchronous tech stack:
* **Asynchronous I/O:** Built on **FastAPI** and **aiosqlite**, ensuring that large I/O operations (writing massive strings to mobile flash memory) do not block the main event loop.
* **Ephemeral Global Tunneling:** Integrates **Cloudflare Quick Tunnels** (`cloudflared`) to bypass carrier NATs, dynamically exposing the local edge node to the public internet via a secure HTTPS reverse tunnel.
* **Zero-Trust UI:** The web interface and API are secured via HTTP Basic Authentication, protecting the node from automated scanners and unauthorized data injection.
* **Zero-Friction Deployment:** A fully automated bash-driven initialization sequence resolves dependencies, manages process IDs, and provisions the environment with a single command.

## ⚙️ Deployment Instructions

1. Clone the repository to your Termux environment:
   ```bash
   git clone https://github.com/aleksbuss/Termux-Text-Vault.git
   cd Termux-Text-Vault

   
1. Execute the initialization script: chmod +x install.sh start.sh
./install.sh

2. CRITICAL: Update your cryptographic credentials in the .env file to prevent unauthorized access.
nano .env

3. Ignite the server daemon: ./start.sh
