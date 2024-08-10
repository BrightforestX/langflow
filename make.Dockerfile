# Use the frontend_deps_stg1.Dockerfile as the first stage
FROM frontend_deps:latest as frontend_deps

# Define the final stage
FROM python:3.12.3-slim  as final

# Install git to clone the repository
RUN apt-get update -o Dir::State::Lists=/var/lib/apt/lists \
    && apt-get install -y --no-install-recommends git npm make curl lsof bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PATH="/root/.local/bin:$PATH:/opt/poetry/bin"

# Set the working directory
WORKDIR /app

RUN git config --global http.postBuffer 524288000

# Clone the specific branch from the GitHub repository
RUN git clone --depth 1 --branch docker-build https://github.com/BrightforestX/langflow.git /app/langflow

# Set the working directory
WORKDIR /app/langflow

# Copy the node_modules from the frontend stage
COPY --from=frontend_deps /app/src/frontend/node_modules /app/langflow/src/frontend/node_modules

# Use the already installed dependencies from the frontend_deps stage
COPY --from=frontend_deps /app/src/frontend/package.json /app/langflow/src/frontend/package.json
COPY --from=frontend_deps /app/src/frontend/package-lock.json /app/langflow/src/frontend/package-lock.json

# Install rollup (if necessary)
RUN npm install @rollup/rollup-linux-x64-gnu

# Set environment variables for LangFlow
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860
ENV LANGFLOW_AUTO_LOGIN=False
ENV LANGFLOW_NEW_USER_IS_ACTIVE=True
ENV BACKEND_URL=http://localhost:7860/

# Expose the necessary ports
EXPOSE 7860

# Define the default command
RUN make backend
