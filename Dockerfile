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

# add backup dir
RUN mkdir -p /var/cache/postgresql/backups
RUN chown -R postgres:postgres /var/cache/postgresql/backups

COPY rootfs /

RUN chown -R postgres:postgres /app

WORKDIR /app

RUN pip install -r requirements.txt

USER postgres

RUN mkdir data

CMD ["python", "governor.py", "postgres.yml"]

ENV DEIS_RELEASE 2.0.0-dev
