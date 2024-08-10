FROM python:3.12.3-slim as python-base

# Install necessary tools in the backend image
USER root
RUN apt-get update -o Dir::State::Lists=/var/lib/apt/lists \
    && apt-get install -y --no-install-recommends make curl gnupg2 tree git bash lsof \
    && apt-get install -y apt-transport-https ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 20.15.0

# Install nvm
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# Use a bash shell and install Node.js using nvm
RUN bash -c "source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && npm install -g npm@latest vite"

# Add node and npm to PATH so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Install Poetry (if necessary)
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

# Clone the specific branch from the GitHub repository
RUN git clone --branch docker-build https://github.com/BrightforestX/langflow.git /app/langflow

# Navigate to the /app/langflow directory
WORKDIR /app/langflow

# Install rollup (if necessary)
RUN npm install @rollup/rollup-linux-x64-gnu

# Build the frontend with local files
RUN make install_frontendci \
    && make build_frontend

# List the contents of the directory
RUN tree
RUN ls

# Set environment variables for LangFlow
# Set environment variables for LangFlow
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
ENV LANGFLOW_AUTO_LOGIN=False
#LANGFLOW_SUPERUSER=admin
#LANGFLOW_SUPERUSER_PASSWORD=password
#LANGFLOW_SECRET_KEY=password
ENV LANGFLOW_NEW_USER_IS_ACTIVE=True
ENV BACKEND_URL=http://localhost:7860/

# Expose the necessary ports
EXPOSE 7860
EXPOSE 3000
