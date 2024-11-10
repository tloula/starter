"""
Armedis Shared
Custom Exceptions
"""


class RetryException(Exception):
    """An exception raised when all retries failed."""

    def __init__(self, message: str):
        self.attempt: int = 0
        self.tries: int = 0
        super().__init__(message)

    @property
    def log_args(self) -> dict:
        """Arguments to be logged."""
        return {
            "tries": self.tries,
            "attempt": self.attempt,
            "exception_message": str(self),
            "exception": self.__class__.__name__,
        }

    @property
    def retry(self) -> bool:
        """Whether to retry the function."""
        return True


class InvalidRoute(Exception):
    """Invalid route exception"""


class DatabaseConnectionError(Exception):
    """Database connection error"""


class StorageConnectionError(Exception):
    """Storage connection error"""


class LivenessProbeError(Exception):
    """Liveness probe error"""


class PotentialHackingAttempt(Exception):
    """Potential hacking attempt"""
