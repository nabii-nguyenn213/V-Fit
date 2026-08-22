FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -m -u 1000 vfit && \
    mkdir -p /app/logs /app/uploads && \
    chown -R vfit:vfit /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install gunicorn python-dotenv

# Copy application code
COPY . .
RUN chown -R vfit:vfit /app

# Switch to non-root user
USER vfit

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD curl -f http://localhost:5000/health || exit 1

# Production: Use gunicorn instead of Flask's built-in server
# Development: Use Flask development server (via docker-compose override)
CMD ["gunicorn", "--workers", "4", "--worker-class", "sync", \
     "--bind", "0.0.0.0:5000", "--timeout", "300", \
     "--access-logfile", "-", "--error-logfile", "-", \
     "api_server:app"]

