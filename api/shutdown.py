"""
Armedis
Shutdown Handler
"""

import sys

from .monitor import get_logger


logger = get_logger(__name__)


def shutdown(*args):
    """Shutdown application"""
    for obj in args:
        try:
            close_method = getattr(obj, 'close_', None)
            if close_method:
                logger.info("Closing %s", str(obj))
                close_method()
        except AttributeError:
            pass
    logger.info("Shutdown complete")


def handle_sigterm(*args):
    """Shutdown handler"""
    logger.info("Received SIGTERM signal. Shutting down...")
    shutdown(*args)
    sys.exit(0)
