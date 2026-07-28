"""Future ESP32 readings endpoint."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Seat, SensorEvent
from app.models.entities import utc_now
from app.schemas import IoTReading, LibraryStatusResponse
from app.services.library_status import build_library_status, get_library_or_404


router = APIRouter(prefix="/iot", tags=["iot"])


@router.post("/readings", response_model=LibraryStatusResponse)
def record_iot_reading(
    reading: IoTReading,
    db: Session = Depends(get_db),
) -> LibraryStatusResponse:
    requested_codes = {seat.code for seat in reading.seats}
    seats = list(db.scalars(select(Seat).where(Seat.code.in_(requested_codes))).all())
    seats_by_code = {seat.code: seat for seat in seats}
    missing_codes = sorted(requested_codes - seats_by_code.keys())
    if missing_codes:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Unknown seat code(s): {', '.join(missing_codes)}.",
        )

    now = utc_now()
    library = get_library_or_404(db)
    library.motion_detected = reading.motion_detected
    library.updated_at = now

    for seat_reading in reading.seats:
        seat = seats_by_code[seat_reading.code]
        seat.is_occupied = seat_reading.occupied
        seat.last_distance_cm = seat_reading.distance_cm
        seat.updated_at = now

    db.add(
        SensorEvent(
            device_id=reading.device_id,
            event_type="iot_reading",
            payload=reading.model_dump(mode="json"),
        )
    )
    db.commit()
    return build_library_status(db)
