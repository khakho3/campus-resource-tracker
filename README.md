# Campus Resource Tracker

Campus Resource Tracker is a hackathon MVP for checking GCTU Library seat
availability before walking to the library. The current release focuses only
on the library. It ships a Flutter app, a FastAPI REST API, and a MySQL schema.

The ESP32, ultrasonic seat sensors, PIR motion sensor, and RFID reader are not
connected yet. The app includes Demo Controls that exercise the same backend
state the hardware will update later.

## What works

- Live `AVAILABLE`, `FULL`, `CLOSED`, and `INACTIVE` library states
- GCTU Library totals, 50/100% occupancy, seats A1/A2, staff, and motion status
- Pull-to-refresh and responsive Material 3 layouts
- Cached information with a visible `OFFLINE` warning and retry action
- Software controls for library access, both seats, motion, RFID, and reset
- Validated FastAPI endpoints, CORS, JSON errors, and automatic Swagger docs
- SQLAlchemy models, MySQL DDL/seed scripts, and sensor-event history
- Isolated SQLite API tests, so tests do not modify a developer's MySQL data

## Architecture

```text
Flutter mobile app
  ├─ HTTP/JSON → FastAPI /api/v1
  └─ shared_preferences cache
                    │
                    ▼
              SQLAlchemy ORM
                    │
                    ▼
                  MySQL

Future ESP32 ── HTTP/JSON ──► POST /api/v1/iot/readings
```

## Repository structure

```text
campus-resource-tracker/
├── mobile/                 Flutter Android application
│   ├── lib/
│   └── test/
├── backend/                FastAPI + SQLAlchemy application
│   ├── app/
│   │   ├── models/
│   │   ├── routers/
│   │   ├── schemas/
│   │   └── services/
│   └── tests/
├── database/               MySQL schema and demo seed SQL
├── docs/                   Inspection report and API examples
├── .gitignore
├── AGENTS.md
└── README.md
```

The initial repository contained only this README and no application, so the
Flutter project was created under `mobile/`; no root Flutter project had to be
moved. See [the original inspection report](docs/INSPECTION_REPORT.md).

## Prerequisites on Windows

Install:

1. Git
2. Python 3.11 or newer
3. MySQL Server 8 and optionally MySQL Workbench
4. Flutter stable and Android Studio
5. An Android emulator, or a physical Android phone with USB debugging

Confirm the main tools from PowerShell:

```powershell
python --version
mysql --version
flutter doctor
```

Resolve any Android licence issues reported by `flutter doctor` before running
the mobile app.

## 1. Set up MySQL

The easiest beginner workflow is:

1. Open MySQL Workbench and connect to the local server.
2. Open and run `database/schema.sql`.
3. Open and run `database/seed.sql`.
4. Refresh Schemas and confirm `campus_resource_tracker` exists.

From the MySQL command-line client, the equivalent commands are:

```sql
SOURCE C:/full/path/to/campus-resource-tracker/database/schema.sql;
SOURCE C:/full/path/to/campus-resource-tracker/database/seed.sql;
```

Both SQL files are idempotent. The seed creates GCTU Library, occupied A1,
available A2, and the present `STAFF-001` demo staff member.

## 2. Set up and run FastAPI

Open PowerShell at the repository root:

```powershell
Set-Location backend
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Open `backend/.env` and replace `YOUR_PASSWORD` with the local MySQL root
password. Never commit that file. The expected setting is:

```dotenv
DATABASE_URL=mysql+mysqlconnector://root:YOUR_PASSWORD@localhost:3306/campus_resource_tracker
```

Create any missing tables and seed records:

```powershell
python -m app.seed
```

Start the API:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Useful URLs:

- Health: <http://127.0.0.1:8000/health>
- Swagger API explorer: <http://127.0.0.1:8000/docs>
- ReDoc: <http://127.0.0.1:8000/redoc>

`AUTO_CREATE_TABLES=true` in `.env.example` also creates missing tables and
seed rows during API startup. The database itself must already exist.

## 3. Run Flutter on an Android emulator

Leave the backend running, open a second PowerShell window, and run:

```powershell
Set-Location mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` is the Android emulator's route to the development computer.
It is the app's default, so the `--dart-define` can be omitted for the standard
Android emulator.

## Run on a physical Android phone

1. Keep the computer and phone on the same Wi-Fi network.
2. Run `ipconfig` and find the computer's Wi-Fi IPv4 address, for example
   `192.168.1.25`.
3. Keep Uvicorn bound to `0.0.0.0`.
4. If Windows Firewall prompts, allow Python on the private network.
5. Run:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Replace the example IP with the computer's actual address. Test
`http://COMPUTER_IP:8000/health` in the phone browser if the app cannot connect.

## Demo Controls

Open the **Demo** tab to:

- Open or close the library
- Mark A1 and A2 available or occupied
- Toggle PIR-style motion detection
- Scan RFID UID `DEMO-RFID-001` to toggle staff presence
- Restore the original demo state

Each action calls the API and refreshes the complete status automatically.
When the API cannot be reached, the app shows the latest cached status as
possibly outdated. If there is no cache, it shows an error with Retry.

## API and state rules

All application endpoints are under `/api/v1`:

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Service health |
| GET | `/api/v1/library/status` | Complete dashboard state |
| PATCH | `/api/v1/library/state` | Open/close or update motion |
| GET | `/api/v1/seats` | Individual seats |
| PATCH | `/api/v1/seats/{seat_id}` | Update a demo seat |
| POST | `/api/v1/staff/scan` | Simulate RFID |
| POST | `/api/v1/iot/readings` | Submit future ESP32 readings |
| POST | `/api/v1/demo/reset` | Restore demo data |

State precedence is:

1. `CLOSED` when the library is not open
2. `INACTIVE` when it is open but no motion is detected
3. `FULL` when it is open, active, and no seats are available
4. `AVAILABLE` when it is open, active, and a seat is available

More request examples are in [docs/API.md](docs/API.md).

## Tests and quality checks

Backend:

```powershell
Set-Location backend
.\.venv\Scripts\Activate.ps1
python -m pytest
python -m compileall app tests
```

Flutter:

```powershell
Set-Location mobile
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Future ESP32 connection

Configure the ESP32 to send JSON over campus Wi-Fi to
`POST /api/v1/iot/readings`:

```json
{
  "device_id": "esp32-library-01",
  "motion_detected": true,
  "seats": [
    {"code": "A1", "occupied": true, "distance_cm": 18.5},
    {"code": "A2", "occupied": false, "distance_cm": 90.2}
  ]
}
```

The endpoint already validates known seat codes, updates motion and seat
readings in one transaction, records the raw event, and returns the refreshed
library status. Before a production deployment, add device authentication,
HTTPS, rate limiting, and per-device credentials.
