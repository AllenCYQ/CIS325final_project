# Dockerfile reference.
# https://docs.docker.com/reference/dockerfile

# Pull the official python version 3.11 Docker container.
FROM python:3.11

# Set working directory.
WORKDIR /app

# Copy the current folder to the container's working directory.
COPY . /app

# Install python dependencies.
RUN pip install --no-cache-dir mlflow flask scikit-learn pandas

# Expose port 5000 for API and start the server.
EXPOSE 5000
CMD ["python", "app.py"]
