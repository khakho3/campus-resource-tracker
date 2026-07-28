"""Staff RFID simulation endpoint."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import SensorEvent, Staff
from app.models.entities import utc_now
from app.schemas import StaffResponse, StaffScan


router = APIRouter(prefix="/staff", tags=["staff"])


@router.post("/scan", response_model=StaffResponse)
def scan_staff(
    scan: StaffScan,
    db: Session = Depends(get_db),
) -> Staff:
    staff_member = db.scalar(select(Staff).where(Staff.rfid_uid == scan.rfid_uid))
    if staff_member is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="RFID card is not registered.",
        )

    staff_member.is_present = not staff_member.is_present
    staff_member.last_scanned_at = utc_now()
    db.add(
        SensorEvent(
            device_id="rfid-demo",
            event_type="staff_scan",
            payload={
                "staff_code": staff_member.staff_code,
                "rfid_uid": staff_member.rfid_uid,
                "is_present": staff_member.is_present,
            },
        )
    )
    db.commit()
    db.refresh(staff_member)
    return staff_member
