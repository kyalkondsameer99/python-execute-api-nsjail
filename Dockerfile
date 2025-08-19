# Dockerfile
# Lightweight Python base
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install build dependencies and nsjail from source, then clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        libprotobuf-dev \
        protobuf-compiler \
        libnl-route-3-dev \
        libtool \
        autoconf \
        automake \
        pkg-config \
        libcap-dev \
        libseccomp-dev \
        flex \
        bison && \
    git clone https://github.com/google/nsjail.git /tmp/nsjail && \
    cd /tmp/nsjail && \
    make && \
    cp nsjail /usr/local/bin/ && \
    cd / && \
    rm -rf /tmp/nsjail && \
    apt-get remove -y build-essential git libtool autoconf automake pkg-config flex bison protobuf-compiler && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# App source
COPY app/ ./app/
COPY wsgi.py ./wsgi.py

# Copy nsjail config to the correct location
COPY app/nsjail.cfg ./nsjail.cfg

EXPOSE 8080
# Production entrypoint (single docker run is enough to start)
CMD ["gunicorn", "-w", "2", "-k", "gthread", "-b", "0.0.0.0:8080", "wsgi:app"]
