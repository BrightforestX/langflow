FROM python:3.10-slim

RUN apt-get update && apt-get install gcc g++ curl build-essential postgresql-server-dev-all -y

RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH="/home/user/.local/bin:${PATH}"

WORKDIR $HOME/app

COPY --chown=user / $HOME/app

RUN pip install langflow -U --user
CMD ["python", "-m", "langflow", "run", "0.0.0.0", "--port", "7860"]