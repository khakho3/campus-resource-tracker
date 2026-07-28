"""Library status calculation and lookup helpers."""

from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Library, Seat, Staff
from app.schemas import LibraryStatusResponse, SeatResponse


def get_library_or_404(db: Session) -> Library:
    library = db.scalar(select(Library).order_by(Library.id).limit(1))
    if library is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Library data has not been seeded.",
        )
    return library


def calculate_state(
    *,
    is_open: bool,
    motion_detected: bool,
    available_seats: int,
) -> str:
    if not is_open:
        return "CLOSED"
    if not motion_detected:
        return "INACTIVE"
    if available_seats == 0:
        return "FULL"
    return "AVAILABLE"


def build_library_status(db: Session) -> LibraryStatusResponse:
    library = get_library_or_404(db)
    seats = list(db.scalars(select(Seat).order_by(Seat.code)).all())
    staff_members = list(db.scalars(select(Staff).order_by(Staff.id)).all())

    total_seats = len(seats)
    occupied_seats = sum(1 for seat in seats if seat.is_occupied)
    available_seats = total_seats - occupied_seats
    occupancy_percentage = (
        round((occupied_seats / total_seats) * 100, 1) if total_seats else 0.0
    )

    timestamps: list[datetime] = [library.updated_at]
    timestamps.extend(seat.updated_at for seat in seats)
    timestamps.extend(
        member.last_scanned_at
        for member in staff_members
        if member.last_scanned_at is not None
    )

    return LibraryStatusResponse(
        library_id=library.id,
        library_name=library.name,
        is_open=library.is_open,
        opening_time=library.opening_time,
        closing_time=library.closing_time,
        motion_detected=library.motion_detected,
        total_seats=total_seats,
        occupied_seats=occupied_seats,
        available_seats=available_seats,
        occupancy_percentage=occupancy_percentage,
        is_full=library.is_open and total_seats > 0 and available_seats == 0,
        status=calculate_state(
            is_open=library.is_open,
            motion_detected=library.motion_detected,
            available_seats=available_seats,
        ),
        staff_present=any(member.is_present for member in staff_members),
        seats=[SeatResponse.model_validate(seat) for seat in seats],
        last_update_time=max(timestamps),
    )
