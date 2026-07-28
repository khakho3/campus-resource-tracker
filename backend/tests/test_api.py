"""API contract and state-rule tests."""

from fastapi.testclient import TestClient


def test_health_endpoint(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "campus-resource-tracker",
    }


def test_available_state(client: TestClient) -> None:
    response = client.get("/api/v1/library/status")

    assert response.status_code == 200
    data = response.json()
    assert data["library_name"] == "GCTU Library"
    assert data["status"] == "AVAILABLE"
    assert data["available_seats"] == 1
    assert data["occupied_seats"] == 1
    assert data["occupancy_percentage"] == 50.0
    assert data["staff_present"] is True


def test_full_state(client: TestClient) -> None:
    seats = client.get("/api/v1/seats").json()
    available_seat = next(seat for seat in seats if seat["code"] == "A2")

    update = client.patch(
        f"/api/v1/seats/{available_seat['id']}",
        json={"is_occupied": True, "last_distance_cm": 18.5},
    )
    status_response = client.get("/api/v1/library/status")

    assert update.status_code == 200
    assert status_response.json()["status"] == "FULL"
    assert status_response.json()["is_full"] is True
    assert status_response.json()["occupancy_percentage"] == 100.0


def test_closed_state(client: TestClient) -> None:
    response = client.patch(
        "/api/v1/library/state",
        json={"is_open": False},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "CLOSED"
    assert response.json()["is_open"] is False


def test_seat_update(client: TestClient) -> None:
    seats = client.get("/api/v1/seats").json()
    seat = next(item for item in seats if item["code"] == "A1")

    response = client.patch(
        f"/api/v1/seats/{seat['id']}",
        json={"is_occupied": False, "last_distance_cm": 92.4},
    )

    assert response.status_code == 200
    assert response.json()["is_occupied"] is False
    assert response.json()["last_distance_cm"] == 92.4


def test_staff_rfid_scan_toggles_presence(client: TestClient) -> None:
    response = client.post(
        "/api/v1/staff/scan",
        json={"rfid_uid": "demo-rfid-001"},
    )

    assert response.status_code == 200
    assert response.json()["staff_code"] == "STAFF-001"
    assert response.json()["is_present"] is False
    assert response.json()["last_scanned_at"] is not None


def test_invalid_seat(client: TestClient) -> None:
    response = client.patch(
        "/api/v1/seats/9999",
        json={"is_occupied": True},
    )

    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


def test_invalid_rfid(client: TestClient) -> None:
    response = client.post(
        "/api/v1/staff/scan",
        json={"rfid_uid": "NOT-REGISTERED"},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "RFID card is not registered."


def test_iot_reading_updates_motion_and_seats(client: TestClient) -> None:
    response = client.post(
        "/api/v1/iot/readings",
        json={
            "device_id": "esp32-library-01",
            "motion_detected": True,
            "seats": [
                {"code": "A1", "occupied": True, "distance_cm": 18.5},
                {"code": "A2", "occupied": False, "distance_cm": 90.2},
            ],
        },
    )

    assert response.status_code == 200
    seats = {seat["code"]: seat for seat in response.json()["seats"]}
    assert seats["A1"]["last_distance_cm"] == 18.5
    assert seats["A2"]["last_distance_cm"] == 90.2


def test_inactive_state(client: TestClient) -> None:
    response = client.patch(
        "/api/v1/library/state",
        json={"motion_detected": False},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "INACTIVE"


def test_demo_reset_restores_initial_state(client: TestClient) -> None:
    client.patch("/api/v1/library/state", json={"is_open": False})

    response = client.post("/api/v1/demo/reset")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "AVAILABLE"
    assert data["is_open"] is True
    assert data["motion_detected"] is True
    assert [seat["is_occupied"] for seat in data["seats"]] == [True, False]
