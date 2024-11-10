# ###################### #
# Armedis API Dockerfile #
# ###################### #

FROM python:3.12

WORKDIR /app

COPY ./api/requirements.txt /app/api/requirements.txt

RUN pip install --no-cache-dir --upgrade -r api/requirements.txt

COPY ./api /app/api
COPY ./.env /app/.env

ARG SERVICE_VERSION
ENV SERVICE_VERSION=${SERVICE_VERSION}
ENV SERVICE_NAME="api"

# Install debugpy for dev environment
# RUN if [ "$SERVICE_VERSION" = "DEV" ]; then pip install --no-cache-dir debugpy; fi

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "80"]
