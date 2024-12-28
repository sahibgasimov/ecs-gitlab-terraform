# Base image d
FROM python:3.9-slim

# Set working directory
WORKDIR /usr/src/app

# Copy application code
COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose application port
EXPOSE 8080

# Start application
CMD ["python", "app.py"]

