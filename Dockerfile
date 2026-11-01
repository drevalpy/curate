# Container of every drevalpy/curate process: drevalpy without its deep-learning extras.
#
# Build it against the drevalpy release the pipeline version pins, given as the named
# build context `drevalpy` (a git URL or a local checkout), and tag it with the pipeline
# version from nextflow.config:
#   docker build --build-context drevalpy=https://github.com/daisybio/drevalpy.git#v2.0.0 \
#       -t ghcr.io/drevalpy/curate:<version> .
# drevalpy's own uv.lock pins every dependency, so the image matches that release exactly.

FROM ghcr.io/astral-sh/uv:0.13 AS uv

FROM python:3.13-slim-bookworm AS builder
COPY --from=uv /uv /usr/local/bin/uv
# git: curve-curator is a git dependency of drevalpy.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
ENV UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1
WORKDIR /opt/build
COPY --from=drevalpy pyproject.toml uv.lock ./
RUN touch README.md \
    && uv sync --frozen --no-dev --no-install-project --no-editable
COPY --from=drevalpy README.md ./
COPY --from=drevalpy src ./src
RUN uv sync --frozen --no-dev --no-editable
# The AWS CLI lets the AWS Batch executor stage task files from S3 without a custom AMI.
RUN uv venv /opt/awscli \
    && VIRTUAL_ENV=/opt/awscli uv pip install awscli

FROM python:3.13-slim-bookworm
# procps: Nextflow reads task metrics with `ps`.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/awscli /opt/awscli
RUN ln -s /opt/awscli/bin/aws /usr/local/bin/aws
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    OPENBLAS_CORETYPE=Haswell
RUN drevalpy --version && drevalpy curate --help > /dev/null && aws --version
