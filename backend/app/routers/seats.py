"""Seat read and update endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Seat, SensorEvent
from app.models.entities import utc_now
from app.schemas import SeatResponse, SeatUpdate


router = APIRouter(prefix="/seats", tags=["seats"])


@router.get("", response_model=list[SeatResponse])
def list_seats(db: Session = Depends(get_db)) -> list[Seat]:
    return list(db.scalars(select(Seat).order_by(Seat.code)).all())


@router.patch("/{seat_id}", response_model=SeatResponse)
def update_seat(
    seat_id: int,
    update: SeatUpdate,
    db: Session = Depends(get_db),
) -> Seat:
    seat = db.get(Seat, seat_id)
    if seat is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Seat {seat_id} was not found.",
        )

    seat.is_occupied = update.is_occupied
    if "last_distance_cm" in update.model_fields_set:
        seat.last_distance_cm = update.last_distance_cm
    seat.updated_at = utc_now()
    db.add(
        SensorEvent(
            device_id="software-demo",
            event_type="seat_state",
            payload={
                "seat_id": seat.id,
                "code": seat.code,
                **update.model_dump(),
            },
        )
    )
    db.commit()
    db.refresh(seat)
    return seat
