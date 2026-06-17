# Multi-stage build. pyswisseph 2.10.3.2 compiles C sources, so the toolchain
# is confined to the build stage and kept out of the runtime image.
FROM python:3.12-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=build /install /usr/local
COPY ephemeris.py main.py LICENSE README.md ./
ENV PORT=8080
EXPOSE 8080
# Single worker: libswe is not thread-safe and the module serialises calls with
# a process-level lock; scale horizontally (more instances), not with threads.
CMD ["sh", "-c", "gunicorn main:app -k uvicorn.workers.UvicornWorker -w 1 -b 0.0.0.0:${PORT}"]
