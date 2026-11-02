# Container of every drevalpy/curate process: drevalpy with CPU-only torch, installed from its own uv.lock.
#   docker build -t ghcr.io/drevalpy/curate:<version> .
# DREVALPY_REF is the daisybio/drevalpy tag, branch or commit to install; a commit of the v2
# branches until drevalpy 2.0.0 is released.

FROM python:3.13-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:0.13 /uv /usr/local/bin/uv
# git: drevalpy and its curve-curator dependency come from git. procps: Nextflow reads task metrics with `ps`.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git procps \
    && rm -rf /var/lib/apt/lists/*
ARG DREVALPY_REF=a8b969af2ee1de06c08cd85e460e9bcf53c08a74
RUN git clone --filter=blob:none https://github.com/daisybio/drevalpy.git /opt/drevalpy \
    && git -C /opt/drevalpy checkout --quiet "$DREVALPY_REF" \
    && UV_PROJECT_ENVIRONMENT=/opt/venv uv sync --project /opt/drevalpy --frozen --no-dev --no-editable --extra cpu \
    && rm -rf /opt/drevalpy /root/.cache
ENV PATH="/opt/venv/bin:$PATH"
