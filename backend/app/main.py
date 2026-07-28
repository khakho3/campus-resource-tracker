"""FastAPI entry point for Campus Resource Tracker."""

from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.config import settings
from app.database import initialize_database
from app.routers import demo, iot, library, seats, staff


logger = logging.getLogger(__name__)


def create_app(*, initialize_on_startup: bool | None = None) -> FastAPI:
    should_initialize = (
        settings.auto_create_tables
        if initialize_on_startup is None
        else initialize_on_startup
    )

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        if should_initialize:
            initialize_database()
        yield

    application = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        description="REST API for the GCTU smart library availability MVP.",
        lifespan=lifespan,
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_origins),
        allow_credentials=settings.cors_origins != ("*",),
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @application.exception_handler(SQLAlchemyError)
    async def database_exception_handler(
        _: Request,
        exception: SQLAlchemyError,
    ) -> JSONResponse:
        logger.exception("Database operation failed", exc_info=exception)
        return JSONResponse(
            status_code=503,
            content={
                "detail": "The database is unavailable. Check DATABASE_URL "
                "and confirm that MySQL is running."
            },
        )

    @application.get("/health", tags=["system"])
    def health() -> dict[str, str]:
        return {"status": "ok", "service": "campus-resource-tracker"}

    api_prefix = "/api/v1"
    application.include_router(library.router, prefix=api_prefix)
    application.include_router(seats.router, prefix=api_prefix)
    application.include_router(staff.router, prefix=api_prefix)
    application.include_router(iot.router, prefix=api_prefix)
    application.include_router(demo.router, prefix=api_prefix)
    return application


app = create_app()
