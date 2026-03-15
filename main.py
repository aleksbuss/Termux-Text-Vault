import os
import secrets
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from pydantic import BaseModel, Field
import aiosqlite

# --- ENVIRONMENT CONFIGURATION ---
API_USERNAME = os.getenv("API_USERNAME", "admin")
API_PASSWORD = os.getenv("API_PASSWORD", "secret")
DB_PATH = "vault.db"
MAX_CONTENT_LENGTH = 15 * 1024 * 1024  # 15 MB hard limit

# --- DATABASE INITIALIZATION ---
async def init_db():
    """Initializes the SQLite schema asynchronously to prevent I/O blocking."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS vault (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        await db.commit()

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield

app = FastAPI(title="Termux Edge Vault", lifespan=lifespan)
security = HTTPBasic()
templates = Jinja2Templates(directory="templates")

# --- SECURITY PROTOCOL ---
def verify_auth(credentials: HTTPBasicCredentials = Depends(security)):
    """Validates incoming requests using constant-time comparison."""
    is_user_ok = secrets.compare_digest(credentials.username, API_USERNAME)
    is_pass_ok = secrets.compare_digest(credentials.password, API_PASSWORD)
    if not (is_user_ok and is_pass_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed. Invalid credentials.",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username

# --- DATA SCHEMAS ---
class TextPayload(BaseModel):
    content: str = Field(..., max_length=MAX_CONTENT_LENGTH)

# --- HEALTH CHECK (used by start.sh before opening tunnel) ---
@app.get("/api/health")
async def health_check():
    return {"status": "ok"}

# --- WEB INTERFACE ---
@app.get("/", response_class=HTMLResponse)
async def render_ui(request: Request, user: str = Depends(verify_auth)):
    return templates.TemplateResponse("index.html", {"request": request})

# --- REST API ENDPOINTS ---
@app.post("/api/push", dependencies=[Depends(verify_auth)])
async def push_text(payload: TextPayload):
    """Persists the text payload to the local SQLite vault (Push operation)."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("INSERT INTO vault (content) VALUES (?)", (payload.content,))
        await db.commit()
    return {"status": "success"}

@app.get("/api/pull", dependencies=[Depends(verify_auth)])
async def pull_text():
    """Retrieves the most recently committed text payload (Pull operation)."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM vault ORDER BY id DESC LIMIT 1") as cursor:
            row = await cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Vault storage is currently empty.")
            return dict(row)

@app.get("/api/archive", dependencies=[Depends(verify_auth)])
async def get_archive():
    """Fetches a lightweight metadata list of all historical payloads."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            "SELECT id, substr(content, 1, 80) as preview, length(content) as size, created_at FROM vault ORDER BY id DESC"
        ) as cursor:
            rows = await cursor.fetchall()
            return [dict(row) for row in rows]

@app.get("/api/archive/{text_id}", dependencies=[Depends(verify_auth)])
async def get_archive_text(text_id: int):
    """Retrieves the complete content of a specific historical payload."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM vault WHERE id = ?", (text_id,)) as cursor:
            row = await cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Requested payload not found.")
            return dict(row)

@app.delete("/api/archive/{text_id}", dependencies=[Depends(verify_auth)])
async def delete_text(text_id: int):
    """Deletes a specific payload from the vault."""
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute("DELETE FROM vault WHERE id = ?", (text_id,))
        await db.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Requested payload not found.")
        return {"status": "deleted"}
