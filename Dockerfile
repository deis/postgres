FROM quay.io/deis/base:v0.3.4

ENV LANG=en_US.utf8 \
	PG_MAJOR=9.4 \
	PG_VERSION=9.4.9-1.pgdg80+1 \
	PGDATA=/var/lib/postgresql/data

# Set this separately from those above since it depends on one of them
ENV PATH=/usr/lib/postgresql/$PG_MAJOR/bin:$PATH

# Add postgres user and group
RUN adduser --system \
	--shell /bin/bash \
	--disabled-password \
	--group \
	postgres

RUN buildDeps='gcc git libffi-dev libssl-dev python-dev python-pip python-setuptools python-wheel'; \
    localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8 && \
    export DEBIAN_FRONTEND=noninteractive && \
	apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
	echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        $buildDeps \
        gosu \
        lzop \
        postgresql-$PG_MAJOR=$PG_VERSION \
        postgresql-contrib-$PG_MAJOR=$PG_VERSION \
        pv \
        python \
        postgresql-common \
        util-linux \
        # swift package needs pkg_resources
        python-pkg-resources && \
	mkdir -p /var/run/postgresql && \
	chown -R postgres /var/run/postgresql && \
	pip install --disable-pip-version-check --no-cache-dir git+https://github.com/deis/wal-e.git@380821a6c4ea4f98a244680d7c6c5b04b8c694b3 \
                                                           google-gax===0.12.5 \
                                                           envdir && \
    # cleanup
    apt-get purge -y --auto-remove $buildDeps && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    # package up license files if any by appending to existing tar
    COPYRIGHT_TAR='/usr/share/copyrights.tar'; \
    gunzip $COPYRIGHT_TAR.gz; tar -rf $COPYRIGHT_TAR /usr/share/doc/*/copyright; gzip $COPYRIGHT_TAR && \
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
