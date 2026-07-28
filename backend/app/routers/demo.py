"""Software-only demo reset endpoint."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import LibraryStatusResponse
from app.seed import seed_demo_data
from app.services.library_status import build_library_status


router = APIRouter(prefix="/demo", tags=["demo"])


@router.post("/reset", response_model=LibraryStatusResponse)
def reset_demo(db: Session = Depends(get_db)) -> LibraryStatusResponse:
    seed_demo_data(db, reset_existing=True, record_event=True)
    return build_library_status(db)
