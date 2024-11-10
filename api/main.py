"""
Armedis Microservices
API
"""

import os
import uuid
from contextlib import asynccontextmanager

from azure.identity import DefaultAzureCredential
from fastapi import FastAPI, Depends, Security
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import trace, metrics
from sqlmodel import Session

from .auth import VerifyToken
from .config import Config
from .database import Database
from .health import healthcheck
from .monitor import initialize_monitoring, get_logger, instrument_app
from .shutdown import shutdown

credential = DefaultAzureCredential(managed_identity_client_id=Config.MSI_CLIENT_ID)
config = Config(credential)
auth = VerifyToken(config)
database = Database(config)

initialize_monitoring(config.application_insights_connection_string)

logger = get_logger(__name__)
tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)
container_id = os.getenv('HOSTNAME') or "api-dev-code"


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("Starting api application")
    yield
    logger.info("Stopping api application")
    shutdown(database)

app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
instrument_app(app)


@app.get("/", response_model=str)
def root():
    return "Armedis API"


@app.get("/liveness")
def liveness():
    return


@app.get("/healthcheck", response_model=dict)
def health(session: Session = Depends(database.get_session)):
    return healthcheck(session)


@app.get("/private", response_model=str)
def private(uid: uuid.UUID = Security(auth.verify)):
    return f"Successfully authenticated with user ID: {uid}"


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
