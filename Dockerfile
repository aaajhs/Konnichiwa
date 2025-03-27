# -------------------------------- Build Stage ------------------------------- #

FROM python:3.13.2-slim-bookworm AS build

WORKDIR /root/app

# ENVs explained:
#   `PYTHONUNBUFFERED=1`: Output python logs immediately rather than buffer
#   `PIP_ROOT_USER_ACTION=ignore`: Suppress pip warning on running as root
#   `POETRY_VIRTUALENVS_IN_PROJECT=true`: Use .venv/ instead of a system-specific cache directory
#   `POETRY_NO_INTERACTION=1`: Suppress interactive prompts from Poetry
#   `PATH="/root/.local/bin:/root/app/.venv/bin:$PATH"`: Add pipx and poetry paths to $PATH

ENV PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PATH="/root/.local/bin:/root/app/.venv/bin:$PATH"

RUN python3 -m pip install --user pipx --no-cache-dir &&\
    python3 -m pipx ensurepath &&\
    pipx install poetry==2.1.1 &&\
    touch /root/app/README.md

COPY pyproject.toml poetry.lock /root/app/
COPY src /root/app/src

RUN poetry install --without dev --no-cache


# ------------------------------- Runtime Stage ------------------------------ #

FROM python:3.13.2-slim-bookworm

EXPOSE 4000
WORKDIR /root/app

ENV PATH="/root/app/.venv/bin:$PATH"

COPY --from=build /root/app/.venv /root/app/.venv
COPY --from=build /root/app/src /root/app/src

ENTRYPOINT ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "4000"]
