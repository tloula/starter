"""
Armedis
Azure Cosmos DB PostgreSQL Database Helper
"""

import contextlib
from typing import TYPE_CHECKING

from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry import trace
from sqlalchemy.pool import QueuePool
from sqlmodel import SQLModel, Session, create_engine

from .monitor import get_logger
from .singleton_meta import SingletonMeta

if TYPE_CHECKING:
    from config import Config

logger = get_logger(__name__)
tracer = trace.get_tracer(__name__)


class Database(metaclass=SingletonMeta):
    """A helper class for interacting with the PostgreSQL Database."""

    def __init__(self, config: "Config") -> None:
        """Returns a SQLAlchemy connection engine to the Azure Cosmos DB PostgreSQL database."""
        password = config.postgresql_password
        coordinator_endpoint = config.postgresql_coordinator_url
        db = config.static.azure_postgresql_database_name
        self.engine = create_engine(
            f"postgresql+psycopg2://citus:{password}@{coordinator_endpoint}:5432/{db}",
            connect_args={
                "sslmode": "require",
                "connect_timeout": 10,
            },
            echo=False,
            poolclass=QueuePool,
            pool_size=20,
        )
        SQLAlchemyInstrumentor().instrument(
            engine=self.engine,
        )
        SQLModel.metadata.create_all(self.engine)

    def __str__(self) -> str:
        return "Azure Cosmos DB PostgreSQL Database"

    def close_(self):
        """Closes the connection to the database."""
        self.engine.dispose()

    def query(self, query: str):
        """Performs a query on the database and returns the result."""
        with Session(self.engine) as session:
            return session.exec(query)

    def _handle_session_exception(self, session: Session) -> None:
        """Handles exceptions during a database session."""
        dirty_count = len(session.dirty)
        new_count = len(session.new)
        deleted_count = len(session.deleted)
        total_changes = dirty_count + new_count + deleted_count

        if total_changes > 0:
            logger.error(
                "An exception occurred during the database session. "
                f"Rolling back {total_changes} changes: "
                f"{dirty_count} dirty, {new_count} new, {deleted_count} deleted."
            )
        else:
            logger.error(
                "An exception occurred during the database session. "
                "No changes to rollback."
            )

        session.rollback()

    @contextlib.contextmanager
    def unit(self):
        """A context manager to handle the lifespan of the database."""
        with tracer.start_as_current_span("RelationalDatabase.unit"):
            session = Session(self.engine, autoflush=False)
            try:
                yield session
                session.commit()
            except Exception:  # pylint: disable=broad-except
                self._handle_session_exception(session)
                raise
            finally:
                session.close()

    def get_session(self):
        """Returns a new session object."""
        session = Session(self.engine, autoflush=False)
        try:
            yield session
            session.commit()
        except Exception:  # pylint: disable=broad-except
            self._handle_session_exception(session)
            raise
        finally:
            session.close()
