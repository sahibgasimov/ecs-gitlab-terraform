# Use an official Python runtime as the base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application code and requirements into the container
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8080 for the Flask application
EXPOSE 8080

# Run the Flask application
CMD ["python", "app.py"]
