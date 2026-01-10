# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
# Use HA's Python base image (Alpine-based) optimized for add-ons
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:3.14-alpine3.23
FROM ${BUILD_FROM}

# Set environment
ENV LANG=C.UTF-8
ENV PYTHONUNBUFFERED=1

# Install system dependencies (Python is already included in base image)
# chromium added for Playwright; build tools for compiling from source
RUN apk add --no-cache \
    chromium \
    chromium-chromedriver \
    build-base \
    openssl-dev \
    libffi-dev \
    jpeg-dev \
    zlib-dev \
    curl \
    git \
    libx11-dev \
    libxcb-dev \
    libxkbcommon-dev \
    freetype-dev \
    mesa-dev \
    ca-certificates

# Ensure python and pip is up to date
RUN python -m pip install --upgrade pip setuptools wheel

# Install websockets and samsung-tv-ws-api from default indexes
RUN pip install --no-cache-dir \
    'websockets==10.4' \
    git+https://github.com/xchwarze/samsung-tv-ws-api.git

# Configure pip to only use PyPI for pyppeteer (HA wheels index doesn't have it)
RUN mkdir -p ~/.pip && echo '[global]\nindex-url = https://pypi.org/simple/\nextra-index-url = https://wheels.home-assistant.io/musllinux-index/' > ~/.pip/pip.conf

# Install pyppeteer for browser automation (Python port of Puppeteer)
RUN pip install --no-cache-dir pyppeteer

# Create app and data directories
RUN mkdir -p /app /data

# Copy addon files
COPY main.py /app/main.py
COPY run.sh /app/run.sh

# Set working directory
WORKDIR /app

# Make run script executable
RUN chmod +x /app/run.sh

# Expose HTTP port for the addon server
EXPOSE 8200

# Run the addon
CMD ["/app/run.sh"]
