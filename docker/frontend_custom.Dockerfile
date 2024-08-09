# Use an official Python runtime as a parent image
FROM python:3.10-slim AS backend

# Set the working directory in the container
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    npm \
    pipx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Copy backend files
COPY src/backend ./src/backend
COPY poetry.lock pyproject.toml ./

# Install Python dependencies
RUN poetry install

# Install dependencies
RUN poetry config virtualenvs.create false && poetry install --no-interaction --no-ansi

RUN poetry add botocore
RUN poetry add pymysql
RUN pipx install langflow --python python3.10 --fetch-missing-python



# Install Uvicorn
RUN pip install uvicorn

# Use an official Node.js runtime as a parent image
FROM node:lts-alpine AS frontend

# Set the working directory in the container
WORKDIR /app

# Copy frontend files
COPY src/frontend ./src/frontend

# Install Node.js dependencies and build
RUN cd src/frontend && npm install && npm run build

# Create a new stage for the final image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy backend and frontend files from the previous stages
COPY --from=backend /app /app
COPY --from=frontend /app/src/frontend/build /app/src/frontend/build

# Expose the necessary ports
EXPOSE 7860 3000

ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

# Command to run the backend
CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860", "--backend-only"]
