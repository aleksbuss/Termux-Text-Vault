# 📦 Termux Text Vault (Self-Hosted Edge Storage)

**Termux Text Vault** is a lightweight, asynchronous edge-storage micro-service engineered specifically for Android devices utilizing the Termux environment. It provides a secure, self-hosted mechanism for transmitting and persisting extensive text payloads (e.g., 10MB+ datasets, logs, or books) across isolated networks without relying on physical media (USB drives) or third-party cloud brokers.

## 🔬 Architectural Overview

Designed with a minimalist "flat" structure, the system leverages a high-performance asynchronous tech stack:

* **Asynchronous I/O:** Built on **FastAPI** and **aiosqlite**, ensuring that large I/O operations (writing massive strings to mobile flash memory) do not block the main event loop.
* **Ephemeral Global Tunneling:** Integrates **Cloudflare Quick Tunnels** (`cloudflared`) to bypass carrier NATs, dynamically exposing the local edge node to the public internet via a secure HTTPS reverse tunnel.
* **Zero-Trust UI:** The web interface and API are secured via HTTP Basic Authentication, protecting the node from automated scanners and unauthorized data injection.
* **Zero-Friction Deployment:** A fully automated bash-driven initialization sequence resolves dependencies (including pre-compiled Android wheels for Rust-based packages), provisions credentials interactively, and boots the environment with a single command.

## ⚙️ Deployment Instructions

1. Clone the repository to your Termux environment:
   ```bash
   git clone https://github.com/aleksbuss/Termux-Text-Vault.git
   cd Termux-Text-Vault
   ```

2. Make scripts executable and run the installer:
   ```bash
   chmod +x install.sh start.sh
   ./install.sh
   ```
   The installer will automatically:
   - Install system packages (`python`, `cloudflared`, `sqlite`, `git`)
   - Install Python dependencies using pre-compiled Android wheels (no Rust toolchain needed)
   - Prompt you to create a **username** and **password** (stored locally in `.env`, never pushed to GitHub)

3. Launch the server:
   ```bash
   ./start.sh
   ```

Upon execution, the system will output an ephemeral `trycloudflare.com` URL. Access this URL from any remote workstation to securely **Push**, **Pull**, and manage your text payloads.

## 🛑 Stopping the Server

```bash
pkill -f uvicorn && pkill -f cloudflared
```

## 🛠 Technical Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3, FastAPI, Uvicorn |
| Database | SQLite3 (via aiosqlite) |
| Validation | Pydantic V2 |
| Frontend | HTML, TailwindCSS (CDN), Vanilla JS |
| Tunneling | Cloudflared (Quick Tunnels) |

## ⚠️ Troubleshooting

**`pydantic-core` build fails:** The installer uses [pre-compiled Android wheels](https://github.com/Eutalix/android-pydantic-core). If those are unavailable, it falls back to compiling with Rust (requires `pkg install rust`, takes ~15 min).

**Backend fails to start:** Check `backend.log` for details: `cat backend.log`

**Tunnel URL is empty:** Verify internet connection and check `tunnel.log`: `cat tunnel.log`
