"""
Armedis
Observability Utilities
"""

import logging
import os
import sys

from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource


service_name: str = os.getenv('SERVICE_NAME', 'unknown')
service_version: str = os.getenv('SERVICE_VERSION', 'unknown')


def initialize_parent_logger():
    """Initializes the parent logger for the service."""
    logger = logging.getLogger(service_name)
    logger.setLevel(logging.DEBUG)
    stream_handler = logging.StreamHandler(sys.stdout)
    log_formatter = logging.Formatter("%(asctime)s [%(processName)s: %(process)d] [%(threadName)s: %(thread)d] [%(levelname)s] %(name)s: %(message)s")  # noqa: E501
    stream_handler.setFormatter(log_formatter)
    logger.addHandler(stream_handler)
    return logger


parent_logger = initialize_parent_logger()


def get_logger(name: str) -> logging.Logger:
    """Sets up the logger for the given logger instance."""
    return parent_logger.getChild(name)


def initialize_monitoring(application_insights_connection_string: str) -> None:
    """Configure OpenTelemetry & Azure Monitor. This function can only be called once."""
    configure_azure_monitor(
        connection_string=application_insights_connection_string,
        resource=Resource(
            attributes={
                "service.name": service_name,
                "service.version": service_version,
            }
        ),
        logger_name=service_name,
        enable_live_metrics=True,
    )
    parent_logger.info("Azure Monitor configured with service name: '%s' and version: '%s'",
                       service_name, service_version)


def instrument_app(app):
    """Instrument the FastAPI app with OpenTelemetry."""
    FastAPIInstrumentor.instrument_app(app)
