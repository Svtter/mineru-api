ARG PYTHON_ENV=python:3.10-slim

FROM $PYTHON_ENV as build
# Allow statements and log messages to immediately appear in the logs
ENV PYTHONUNBUFFERED True
RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl g++ libopencv-dev python3.10-pip && \
    rm -rf /var/lib/apt/lists/*
RUN pip install uv

RUN mkdir -p /app
WORKDIR /app

COPY pyproject.toml uv.lock ./

ENV PATH="/root/.local/bin:$PATH"
RUN uv sync

FROM $PYTHON_ENV as prod

# Allow statements and log messages to immediately appear in the logs
ENV PYTHONUNBUFFERED True
# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
COPY magic-pdf.json /root

COPY --from=build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=build /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=build /usr/local/bin/magic-pdf /usr/local/bin/magic-pdf
COPY --from=build /usr/local/bin/uvicorn /usr/local/bin/uvicorn

RUN uv run python download_models.py

CMD ["uv", "run", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "3000"]

