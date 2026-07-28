"""Library status and state endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import SensorEvent
from app.models.entities import utc_now
from app.schemas import LibraryStateUpdate, LibraryStatusResponse
from app.services.library_status import build_library_status, get_library_or_404


router = APIRouter(prefix="/library", tags=["library"])


@router.get("/status", response_model=LibraryStatusResponse)
def library_status(db: Session = Depends(get_db)) -> LibraryStatusResponse:
    return build_library_status(db)


@router.patch("/state", response_model=LibraryStatusResponse)
def update_library_state(
    update: LibraryStateUpdate,
    db: Session = Depends(get_db),
) -> LibraryStatusResponse:
    library = get_library_or_404(db)
    payload = update.model_dump(exclude_none=True)
    if update.is_open is not None:
        library.is_open = update.is_open
    if update.motion_detected is not None:
        library.motion_detected = update.motion_detected
    library.updated_at = utc_now()
    db.add(
        SensorEvent(
            device_id="software-demo",
            event_type="library_state",
            payload=payload,
        )
    )
    db.commit()
    return build_library_status(db)
