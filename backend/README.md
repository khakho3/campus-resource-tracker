# FastAPI backend

The backend exposes the GCTU Library REST API and stores state through
SQLAlchemy. Production/local development uses MySQL; tests override the session
with an isolated in-memory SQLite database.

## Windows quick start

```powershell
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `.env`, create the `campus_resource_tracker` MySQL database with
`../database/schema.sql`, then run:

```powershell
python -m app.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger documentation is available at <http://127.0.0.1:8000/docs>.

Run tests with:

```powershell
python -m pytest
```
