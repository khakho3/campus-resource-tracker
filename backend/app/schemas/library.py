"""Request and response schemas for library resources."""

from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class StrictSchema(BaseModel):
    model_config = ConfigDict(extra="forbid")


class LibraryStateUpdate(StrictSchema):
    is_open: bool | None = None
    motion_detected: bool | None = None

    @model_validator(mode="after")
    def has_update(self) -> "LibraryStateUpdate":
        if self.is_open is None and self.motion_detected is None:
            raise ValueError("Provide is_open or motion_detected.")
        return self


class SeatUpdate(StrictSchema):
    is_occupied: bool
    last_distance_cm: float | None = Field(default=None, ge=0, le=1000)


class StaffScan(StrictSchema):
    rfid_uid: str = Field(min_length=1, max_length=120)

    @field_validator("rfid_uid")
    @classmethod
    def normalize_rfid(cls, value: str) -> str:
        return value.strip().upper()


class IoTSeatReading(StrictSchema):
    code: str = Field(min_length=1, max_length=20)
    occupied: bool
    distance_cm: float | None = Field(default=None, ge=0, le=1000)

    @field_validator("code")
    @classmethod
    def normalize_code(cls, value: str) -> str:
        return value.strip().upper()


class IoTReading(StrictSchema):
    device_id: str = Field(min_length=1, max_length=120)
    motion_detected: bool
    seats: list[IoTSeatReading] = Field(min_length=1, max_length=100)

    @field_validator("device_id")
    @classmethod
    def normalize_device_id(cls, value: str) -> str:
        return value.strip()

    @model_validator(mode="after")
    def unique_seat_codes(self) -> "IoTReading":
        codes = [seat.code for seat in self.seats]
        if len(codes) != len(set(codes)):
            raise ValueError("Seat codes must be unique within one reading.")
        return self


class SeatResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    code: str
    is_occupied: bool
    last_distance_cm: float | None
    updated_at: datetime


class StaffResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    staff_code: str
    name: str
    rfid_uid: str
    is_present: bool
    last_scanned_at: datetime | None


class LibraryStatusResponse(BaseModel):
    library_id: int
    library_name: str
    is_open: bool
    opening_time: time
    closing_time: time
    motion_detected: bool
    total_seats: int
    occupied_seats: int
    available_seats: int
    occupancy_percentage: float
    is_full: bool
    status: str
    staff_present: bool
    seats: list[SeatResponse]
    last_update_time: datetime
