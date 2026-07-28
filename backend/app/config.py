"""Environment-backed application configuration."""

from dataclasses import dataclass
import os
from pathlib import Path

from dotenv import load_dotenv


BACKEND_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIR / ".env")


def _as_bool(value: str | None, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "Campus Resource Tracker API")
    database_url: str = os.getenv(
        "DATABASE_URL",
        "mysql+mysqlconnector://root:YOUR_PASSWORD@localhost:3306/"
        "campus_resource_tracker",
    )
    cors_origins: tuple[str, ...] = tuple(
        origin.strip()
        for origin in os.getenv("CORS_ORIGINS", "*").split(",")
        if origin.strip()
    )
    auto_create_tables: bool = _as_bool(
        os.getenv("AUTO_CREATE_TABLES"),
        True,
    )


settings = Settings()
