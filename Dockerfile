# ── Stage 1: Build Frontend (Vite React) ─────────────────────────
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend

# Install dependencies using package-lock.json
COPY frontend/package*.json ./
RUN npm ci

# Copy source code and build production assets into /app/frontend/dist
COPY frontend/ ./
RUN npm run build

# ── Stage 2: Python FastAPI Runtime ───────────────────────────────
FROM python:3.11-slim
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install system dependencies required for psycopg / libpq
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python backend dependencies
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application source
COPY backend/ ./backend

# Ensure directory for generated policy PDFs exists
RUN mkdir -p ./backend/generated_policies

# Copy built frontend static files from Stage 1 into backend/static
COPY --from=frontend-builder /app/frontend/dist ./backend/static

WORKDIR /app/backend

# Railway / cloud environments set the $PORT environment variable
EXPOSE 8000
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]

