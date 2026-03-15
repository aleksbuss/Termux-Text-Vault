# 📦 Termux Text Vault

**Turn your Android phone into a personal text server accessible from anywhere in the world.**

Ever needed to transfer a long script, config file, or 10MB of text to a remote server — but all you have is an SSH terminal? No USB drive, no cloud account, no email? Termux Text Vault solves this. Your phone becomes a secure HTTPS server that you can push text to and pull text from — using a browser or a terminal — from any device on the planet.

---

## How It Works

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│  Your PC    │         │  Cloudflare CDN  │         │  Your Phone │
│  (browser)  │◄───────►│  (HTTPS tunnel)  │◄───────►│  (Termux)   │
└─────────────┘         └──────────────────┘         └─────────────┘
                               ▲
┌─────────────┐                │
│  VPS        │                │
│             │◄───────────────┘
│  (terminal) │
└─────────────┘
```

1. Your phone runs a small Python server inside Termux
2. Cloudflare creates a free HTTPS tunnel — your phone gets a public URL like `https://abc-def-ghi.trycloudflare.com`
3. You open that URL in a browser (Web UI) or use the `vault` CLI tool from any terminal
4. Everything is protected with a username and password that you set during installation

---

## Part 1: Setting Up the Server (on your Android phone)

### What you need

- An Android phone with [Termux](https://f-droid.org/packages/com.termux/) installed (get it from F-Droid, **not** Google Play)
- Internet connection (Wi-Fi or mobile data)

### Step 1 — Open Termux and clone the project

```bash
git clone https://github.com/aleksbuss/Termux-Text-Vault.git
cd Termux-Text-Vault
```

### Step 2 — Run the installer

```bash
chmod +x install.sh start.sh
./install.sh
```

This will:
- Install all required packages (`python`, `cloudflared`, `sqlite`, etc.)
- Install Python libraries (FastAPI, aiosqlite, Pydantic, etc.)
- Ask you to create a **username** and **password**

**Important:** Remember your username and password — you will need them every time you connect to the Vault from another device.

The installer output will look something like this:
```
[+] Initializing Termux Text Vault dependencies...
[+] Installing Python dependencies...
[✔] All dependencies installed successfully!

==================================================
🛡️  SECURITY SETUP (Local Only)
==================================================
Your Vault will be exposed to the global internet.
Let's create a secure login so nobody else can access your data.

Enter a Username (default: admin): myname
Enter a Password: ********

[✔] Credentials saved to local .env file.
[✔] Installation complete! Run: ./start.sh
```

### Step 3 — Start the server

```bash
./start.sh
```

If everything works, you'll see:
```
==================================================
🚀 EDGE SERVER IS ONLINE
==================================================
🌍 Public URL: https://abc-def-ghi.trycloudflare.com
👤 Username:   myname
==================================================
```

**Copy that URL** — this is your access point. It works from anywhere in the world as long as the server is running on your phone.

### Step 4 — Stopping the server

When you're done, stop it with:
```bash
pkill -f uvicorn && pkill -f cloudflared
```

To start again later, just `cd Termux-Text-Vault && ./start.sh` — it will generate a new URL each time.

---

## Part 2: Using the Vault from a Browser (PC, laptop, tablet)

This is the easiest way. Open the tunnel URL in any browser:

```
https://abc-def-ghi.trycloudflare.com
```

Your browser will ask for a username and password — enter the credentials you created during installation.

You'll see the Web UI with these controls:

| Button | What it does |
|--------|-------------|
| **⬆ Push** | Saves the text from the editor to your phone |
| **⬇ Pull** | Loads the most recent saved text into the editor |
| **📋 Copy** | Copies the editor contents to your clipboard |
| **📁 File** | Loads a `.txt` file from your computer into the editor |
| **📚 Archive** | Opens a sidebar with all previously saved texts |

**Typical workflow:**
1. Paste a long script or text into the editor
2. Click **Push** — it's now saved on your phone
3. Go to another device, open the same URL, click **Pull** — your text is there

---

## Part 3: Using the Vault from a Terminal (VPS, SSH, any server)

This is where the Vault becomes truly powerful. When you're connected to a remote server via SSH and there's no browser — only a terminal — you can use the `vault` CLI client.

### Step 1 — Install the CLI client on your remote machine

Choose one option depending on your situation:

**Option A — Linux server with root access (most VPS):**
```bash
sudo curl -sL https://raw.githubusercontent.com/aleksbuss/Termux-Text-Vault/main/vault -o /usr/local/bin/vault && sudo chmod +x /usr/local/bin/vault
```

**Option B — macOS:**
```bash
sudo bash -c 'curl -sL https://raw.githubusercontent.com/aleksbuss/Termux-Text-Vault/main/vault > /usr/local/bin/vault && chmod +x /usr/local/bin/vault'
```

**Option C — No root / no sudo (works everywhere):**
```bash
curl -sL https://raw.githubusercontent.com/aleksbuss/Termux-Text-Vault/main/vault > ~/vault && chmod +x ~/vault
```
If you use Option C, type `~/vault` instead of `vault` in all commands below.

### Step 2 — Connect to your Vault

```bash
vault setup
```

It will ask three questions:
```
Vault URL (e.g. https://xxx.trycloudflare.com): https://abc-def-ghi.trycloudflare.com
Username: myname
Password: ********

Testing connection... ✔ Connected successfully!
```

Your credentials are saved locally in `~/.vault_config`. You only need to run `vault setup` once per machine (or again if your tunnel URL changes).

### Step 3 — Use the interactive menu

Just type:
```bash
vault
```

You'll see:
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

- Press `1` to pull the latest text and display it in the terminal
- Press `2` to type or paste new text (press `Ctrl+D` when done to send it)
- Press `3` to push a file from the server's disk
- Press `4` to see a table of all saved entries
- Press `5` to retrieve a specific entry by its ID number
- Press `6` to delete an entry

### Step 4 — Or use direct commands (for scripting)

If you prefer one-liners or want to use Vault in scripts:

```bash
# Get the latest text and print it
vault pull

# Save the latest text to a file
vault pull > script.sh

# Push a short text
vault push "apt update && apt install nginx -y"

# Push the contents of a file
vault push < myconfig.yaml

# Pipe output of a command into the Vault
cat /var/log/syslog | tail -50 | vault push

# Show all saved entries as a table
vault list

# Get a specific entry by ID (shown in the list)
vault get 5

# Save a specific entry to a file
vault get 5 > output.txt

# Delete an entry
vault delete 5
```

---

## Part 4: Real-World Examples

### Example 1: Deploy a script to a new VPS

You just bought a VPS. You need to run a 200-line installation script on it. Here's how:

**On your PC (browser):**
1. Open your Vault URL in a browser
2. Paste the entire script into the editor
3. Click **Push**

**On your VPS (SSH terminal):**
```bash
# Install the CLI client (once)
sudo curl -sL https://raw.githubusercontent.com/aleksbuss/Termux-Text-Vault/main/vault -o /usr/local/bin/vault && sudo chmod +x /usr/local/bin/vault

# Connect to your Vault (once)
vault setup

# Pull the script and run it
vault pull > install.sh && chmod +x install.sh && bash install.sh
```

### Example 2: Send server logs to your phone

Something went wrong on your server. You want to read the logs later on your phone or PC:

**On your VPS:**
```bash
tail -200 /var/log/nginx/error.log | vault push
```

**On your PC (browser):**
1. Open your Vault URL
2. Click **Pull**
3. The logs appear in the editor

### Example 3: Transfer text between two servers

You have Server A and Server B. You need to move a config file between them:

**On Server A:**
```bash
vault push < /etc/nginx/nginx.conf
```

**On Server B:**
```bash
vault pull > /etc/nginx/nginx.conf
```

### Example 4: Quick notes while working

You're deep in a server setup and need to remember something. Push a note:

```bash
vault push "TODO: open port 443, add SSL cert, restart nginx"
```

Later, from any device:
```bash
vault pull
```

---

## 📡 API Reference

For developers who want to integrate the Vault with other tools. All endpoints (except `/api/health`) require HTTP Basic Authentication.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/health` | Health check (no auth required) |
| `GET` | `/api/pull` | Returns the most recently saved text |
| `POST` | `/api/push` | Saves new text. Body: `{"content": "your text"}` |
| `GET` | `/api/archive` | Returns a list of all saved entries (preview + metadata) |
| `GET` | `/api/archive/{id}` | Returns the full content of a specific entry |
| `DELETE` | `/api/archive/{id}` | Deletes a specific entry |

### Using the API directly with curl

If you don't want to install the CLI client, you can use `curl` directly:

```bash
# Set your URL and credentials
VAULT_URL="https://abc-def-ghi.trycloudflare.com"
VAULT_AUTH="myname:mypassword"

# Pull the latest text
curl -s -u $VAULT_AUTH $VAULT_URL/api/pull \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['content'])"

# Push text
curl -s -u $VAULT_AUTH -X POST \
  -H "Content-Type: application/json" \
  -d '{"content": "hello from curl"}' \
  $VAULT_URL/api/push

# Push a file
curl -s -u $VAULT_AUTH -X POST \
  -H "Content-Type: application/json" \
  -d "{\"content\": $(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" < myfile.txt)}" \
  $VAULT_URL/api/push

# List all entries
curl -s -u $VAULT_AUTH $VAULT_URL/api/archive | python3 -m json.tool
```

---

## 🛠 Technical Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3, FastAPI, Uvicorn |
| Database | SQLite3 (via aiosqlite) |
| Validation | Pydantic V2 |
| Frontend | HTML, TailwindCSS (CDN), Vanilla JS |
| CLI Client | Bash, curl, python3 |
| Tunneling | Cloudflared (Quick Tunnels) |

---

## ⚠️ Troubleshooting

### Installation fails with `pydantic-core` error
The installer uses [pre-compiled Android wheels](https://github.com/Eutalix/android-pydantic-core) to skip the Rust compilation. If those are unavailable for your Python version, it falls back to compiling from source (requires Rust, takes ~15 minutes). If that also fails, try updating Termux: `pkg update -y && pkg upgrade -y`.

### Backend fails to start
Check the log file:
```bash
cat backend.log
```

### Tunnel URL is empty
Make sure your phone has internet access and check:
```bash
cat tunnel.log
```

### `vault setup` says "Connection failed"
- Make sure `start.sh` is running on your phone
- Check that you're using the correct URL (it changes every time you restart the server)
- Verify your username and password match what you set during `./install.sh`

### `permission denied` when installing the CLI client
Use `sudo` (see Part 3, Step 1 above), or install to your home directory with Option C.

### `curl` is not installed on the VPS
```bash
apt install curl -y    # Debian/Ubuntu
yum install curl -y    # CentOS/RHEL
```

### Tunnel URL changes every restart
This is normal — Cloudflare Quick Tunnels generate a new random URL each time. After restarting `start.sh`, run `vault setup` again on your remote machines to update the URL.

---

## 📄 License

MIT — use it however you want.
