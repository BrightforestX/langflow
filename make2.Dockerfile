# syntax=docker/dockerfile:1
# Keep this syntax directive! It's used to enable Docker BuildKit

# Use the Langflow base image
FROM langflowai/langflow:latest

# Fix permission issue and install necessary tools
USER root

# Install make, curl, npm, gpg, and Docker
RUN apt-get update -o Dir::State::Lists=/var/lib/apt/lists \
    && apt-get install -y --no-install-recommends make curl npm gnupg2 \
    && apt-get install -y apt-transport-https ca-certificates \
    && apt-get install -y lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get update 
    



# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.8.2 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PATH="/root/.local/bin:$PATH"

# Set the working directory
WORKDIR /app

# Copy the entire repository
COPY . .

# Install dependencies and build the frontend
RUN poetry --version \
    && npm --version \
    && make build_frontend

# Check if frontend directory exists (Debugging step)
RUN ls -la src/backend/base/langflow/

# Set environment variables for LangFlow
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

# Expose the necessary ports
EXPOSE 7860
EXPOSE 3000

# Define the default command
CMD ["make", "run_frontend"]
