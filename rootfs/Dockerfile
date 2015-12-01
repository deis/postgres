FROM postgres:9.4

RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    libpq-dev \
    libyaml-dev \
    lzop \
    pv \
    python \
    python-dev \
    python-pip \
    --no-install-recommends \
    && rm -rf /var/cache/apt/*

COPY . /
WORKDIR /app

ENV PGDATA /app/data

RUN pip install -r requirements.txt

ENV DEIS_RELEASE 2.0.0-dev
