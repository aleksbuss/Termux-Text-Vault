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

Upon execution, the system will output an ephemeral `trycloudflare.com` URL (e.g., `https://abc-def-ghi.trycloudflare.com`). This URL is your access point from **any device in the world** — whether it has a browser or only a terminal.

---

## 🖥 Usage: Web Browser

Open the tunnel URL in any browser, enter your credentials, and you get the full Web UI with **Push**, **Pull**, **Copy**, **File Upload**, and **Archive** functionality.

---

## 🔧 Usage: Remote Server / VPS (CLI Client)

When you're working on a remote server that has **no browser** — only SSH and a terminal — you don't need to type raw `curl` commands. The repo includes an interactive CLI client (`vault`) that gives you a full terminal interface to your Vault.

### One-line install on any VPS

```bash
curl -sL https://raw.githubusercontent.com/aleksbuss/Termux-Text-Vault/main/vault > /usr/local/bin/vault \
  && chmod +x /usr/local/bin/vault
```

### First-time setup

```bash
vault setup
```

It will ask for your tunnel URL, username, and password — then test the connection. Credentials are saved to `~/.vault_config` (mode 600).

### Interactive mode

Just type `vault` with no arguments to open the interactive menu:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Vault — https://abc-def-ghi.trycloudflare.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1) Pull latest       4) List archive
  2) Push text         5) Get by ID
  3) Push file         6) Delete by ID

  s) Setup             q) Quit

  Choose:
```

### Direct commands (scriptable)

```bash
vault pull                        # Print latest entry to stdout
vault pull > deploy.sh            # Save to file
vault push "apt install nginx"    # Push inline text
vault push < config.yaml          # Push file content
cat error.log | vault push        # Pipe to push
vault list                        # Show archive table
vault get 3                       # Print entry #3
vault get 3 > out.txt             # Save entry #3 to file
vault delete 3                    # Delete entry #3
```

### Real-world workflow

**Scenario:** Deploy a 200-line setup script to a fresh VPS.

```bash
# On your PC: open Vault in browser, paste the script, click Push

# On VPS:
ssh root@185.x.x.x
vault pull > install.sh && bash install.sh

# Send logs back:
tail -100 /var/log/syslog | vault push

# On your PC: click Pull in the browser to read the logs
```

---

## 📡 API Reference

For advanced usage or integration with other tools. All endpoints require HTTP Basic Authentication (except `/api/health`).

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check (no auth) |
| `GET` | `/api/pull` | Get the most recent entry |
| `POST` | `/api/push` | Save new text `{"content": "..."}` |
| `GET` | `/api/archive` | List all entries (preview + metadata) |
| `GET` | `/api/archive/{id}` | Get full content of a specific entry |
| `DELETE` | `/api/archive/{id}` | Delete a specific entry |

### Raw curl examples

```bash
# Pull
curl -s -u user:pass $VAULT_URL/api/pull \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['content'])"

# Push
curl -s -u user:pass -X POST -H "Content-Type: application/json" \
  -d '{"content": "hello world"}' $VAULT_URL/api/push

# List
curl -s -u user:pass $VAULT_URL/api/archive | python3 -m json.tool
```

---

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
| CLI Client | Bash, curl, python3 |
| Tunneling | Cloudflared (Quick Tunnels) |

## ⚠️ Troubleshooting

**`pydantic-core` build fails:** The installer uses [pre-compiled Android wheels](https://github.com/Eutalix/android-pydantic-core). If those are unavailable, it falls back to compiling with Rust (requires `pkg install rust`, takes ~15 min).

**Backend fails to start:** Check `backend.log` for details: `cat backend.log`

**Tunnel URL is empty:** Verify internet connection and check `tunnel.log`: `cat tunnel.log`

**`curl` not available on VPS:** Install it: `apt install curl -y`
