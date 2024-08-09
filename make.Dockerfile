# Use the frontend_deps_stg1.Dockerfile as the first stage
FROM frontend_deps:latest AS frontend_deps

# Define the final stage
FROM python:3.9-slim AS final

# Set environment variables
ENV POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PATH="/root/.local/bin:$PATH"

# Set the working directory
WORKDIR /app

# Copy the backend code to the backend stage
COPY . .

# Copy the node_modules from the frontend stage
COPY --from=frontend_deps /app/src/frontend/node_modules /app/src/frontend/node_modules

RUN npm install @rollup/rollup-linux-x64-gnu

# Build the frontend with local files
RUN install_frontendc \
    && make build_frontend

# Set environment variables for LangFlow
ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

# Expose the necessary ports
EXPOSE 7860
EXPOSE 3000

# Define the default command
CMD ["make", "frontend"]