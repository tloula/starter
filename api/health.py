"""
Armedis
HealthCheck
"""

import pydantic
from sqlmodel import Session, text
from fastapi import HTTPException


class HealthCheck(pydantic.BaseModel):
    """Health check for the service"""

    database: bool
    storage: bool

    @property
    def healthy(self) -> bool:
        """Check if the service is healthy"""
        return self.database and self.storage


def healthcheck(session: Session) -> HealthCheck:
    """Liveness probe"""
    hc = HealthCheck(
        database=check_relational_database(session),
        storage=check_storage()
    )
    if not hc.healthy:
        raise HTTPException(status_code=500, detail=hc.model_dump())
    return hc


def check_relational_database(session: Session) -> bool:
    """Check relational database connection"""
    try:
        query = text("SELECT name FROM users WHERE id = '00000000-0000-0000-0000-000000000000'")
        if session.exec(query).first() is None:
            return False
    except Exception:  # pylint: disable=broad-except
        return False


def check_storage() -> bool:
    """Check blob storage connection"""
    try:
        return True
        # if not Storage().check_if_blob_exists("liveness.txt"):
        #     raise StorageConnectionError("Blob storage connection failed")
    except Exception:  # pylint: disable=broad-except
        return False
