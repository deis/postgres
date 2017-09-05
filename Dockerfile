FROM quay.io/deis/base:v0.3.6

ENV LANG=en_US.utf8 \
    PG_MAJOR=9.4 \
    PG_VERSION=9.4.14-1.pgdg16.04+1 \
    PGDATA=/var/lib/postgresql/data

# Set this separately from those above since it depends on one of them
ENV PATH=/usr/lib/postgresql/$PG_MAJOR/bin:$PATH

# Add postgres user and group
RUN adduser --system \
    --shell /bin/bash \
    --disabled-password \
    --group \
    postgres

RUN buildDeps='gcc git libffi-dev libssl-dev python3-dev python3-pip python3-wheel' && \
    localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8 && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        $buildDeps \
        gosu \
        lzop \
        postgresql-$PG_MAJOR=$PG_VERSION \
        postgresql-contrib-$PG_MAJOR=$PG_VERSION \
        pv \
        python3 \
        postgresql-common \
        util-linux \
        # swift package needs pkg_resources and setuptools
        python3-pkg-resources \
        python3-setuptools && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    mkdir -p /run/postgresql && \
    chown -R postgres /run/postgresql && \
    pip install --disable-pip-version-check --no-cache-dir \
        envdir==0.7 \
        wal-e[aws,azure,google,swift]==v1.0.2 \
        # pin azure-storage to version wal-e uses (see docker-entrypoint.sh)
        azure-storage==0.20.0 && \
    # "upgrade" boto to 2.43.0 + the patch to fix minio connections
    pip install --disable-pip-version-check --no-cache-dir --upgrade git+https://github.com/deis/boto@88c980e56d1053892eb940d43a15a68af4ebb5e6 && \
    # cleanup
    apt-get purge -y --auto-remove $buildDeps && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    # package up license files if any by appending to existing tar
    COPYRIGHT_TAR='/usr/share/copyrights.tar' && \
    gunzip -f $COPYRIGHT_TAR.gz && \
    tar -rf $COPYRIGHT_TAR /usr/share/doc/*/copyright && \
    gzip $COPYRIGHT_TAR && \
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBC* && \
    bash -c "mkdir -p /usr/share/man/man{1..8}"

COPY rootfs /
ENV WALE_ENVDIR=/etc/wal-e.d/env
RUN mkdir -p $WALE_ENVDIR

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
