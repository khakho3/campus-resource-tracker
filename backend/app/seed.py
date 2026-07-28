"""Idempotent seed helpers and command-line entry point."""

from datetime import time

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Library, Seat, SensorEvent, Staff
from app.models.entities import utc_now


def seed_demo_data(
    db: Session,
    *,
    reset_existing: bool = False,
    record_event: bool = False,
) -> None:
    """Create demo rows, optionally restoring every row to its initial state."""

    now = utc_now()
    library = db.scalar(select(Library).where(Library.name == "GCTU Library"))
    if library is None:
        library = Library(
            name="GCTU Library",
            is_open=True,
            opening_time=time(8, 0),
            closing_time=time(20, 0),
            motion_detected=True,
            updated_at=now,
        )
        db.add(library)
    elif reset_existing:
        library.is_open = True
        library.opening_time = time(8, 0)
        library.closing_time = time(20, 0)
        library.motion_detected = True
        library.updated_at = now

    demo_seats = {"A1": True, "A2": False}
    for code, occupied in demo_seats.items():
        seat = db.scalar(select(Seat).where(Seat.code == code))
        if seat is None:
            db.add(
                Seat(
                    code=code,
                    is_occupied=occupied,
                    last_distance_cm=None,
                    updated_at=now,
                )
            )
        elif reset_existing:
            seat.is_occupied = occupied
            seat.last_distance_cm = None
            seat.updated_at = now

    staff_member = db.scalar(
        select(Staff).where(Staff.staff_code == "STAFF-001")
    )
    if staff_member is None:
        db.add(
            Staff(
                staff_code="STAFF-001",
                name="Demo Library Staff",
                rfid_uid="DEMO-RFID-001",
                is_present=True,
                last_scanned_at=None,
            )
        )
    elif reset_existing:
        staff_member.name = "Demo Library Staff"
        staff_member.rfid_uid = "DEMO-RFID-001"
        staff_member.is_present = True
        staff_member.last_scanned_at = None

    if record_event:
        db.add(
            SensorEvent(
                device_id="software-demo",
                event_type="demo_reset",
                payload={"reset": True},
                created_at=now,
            )
        )
    db.commit()


if __name__ == "__main__":
    from app.database import Base, SessionLocal, engine

    Base.metadata.create_all(bind=engine)
    with SessionLocal() as session:
        seed_demo_data(session)
    print("Database tables and GCTU Library demo data are ready.")
