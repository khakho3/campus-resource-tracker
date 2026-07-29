# API examples

Base URL for local development: `http://127.0.0.1:8000`.

FastAPI also provides interactive request documentation at `/docs`.

## Complete library status

```http
GET /api/v1/library/status
```

The response contains the library name and hours, motion and staff state, all
seat counts, occupancy percentage, computed state, individual seats, and the
latest update time.

## Change library state

```http
PATCH /api/v1/library/state
Content-Type: application/json

{"is_open": false}
```

Motion can be changed independently:

```json
{"motion_detected": false}
```

## Change a seat

First use `GET /api/v1/seats` to obtain the database ID, then:

```http
PATCH /api/v1/seats/1
Content-Type: application/json

{"is_occupied": true, "last_distance_cm": 18.5}
```

## Simulate staff RFID

```http
POST /api/v1/staff/scan
Content-Type: application/json

{"rfid_uid": "DEMO-RFID-001"}
```

Each valid scan toggles the demo staff member between present and absent.
Unknown RFID values return HTTP 404.

For hardware testing, scan the RFID card once in Serial Monitor and register
that UID for `STAFF-001` in MySQL before expecting HTTP 200.

## Submit ESP32 readings

```http
POST /api/v1/iot/readings
Content-Type: application/json

{
  "device_id": "esp32-library-01",
  "motion_detected": true,
  "seats": [
    {"code": "A1", "occupied": true, "distance_cm": 18.5},
    {"code": "A2", "occupied": false, "distance_cm": 90.2}
  ]
}
```

Unknown or duplicate seat codes are rejected. Valid readings update all values
and add the submitted payload to `sensor_events`.

The ESP32 wiring and full Arduino sketch are documented in
[ESP32_HARDWARE.md](ESP32_HARDWARE.md).

## Restore the demo

```http
POST /api/v1/demo/reset
```

This restores an open, active library; occupied A1; available A2; and present
demo staff.
