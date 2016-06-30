FROM quay.io/deis/base:0.2.0

ENV LANG=en_US.utf8 \
	PG_MAJOR=9.4 \
	PG_VERSION=9.4.8-1.pgdg80+1 \
	PGDATA=/var/lib/postgresql/data \
	WALE_ENVDIR=/etc/wal-e.d/env

# Set this separately from those above since it depends on one of them
ENV PATH=/usr/lib/postgresql/$PG_MAJOR/bin:$PATH

# Add postgres user and group
RUN adduser --system \
	--shell /bin/bash \
	--disabled-password \
	--group \
	postgres

COPY . /

RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
	&& curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8 \
	&& apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
	&& echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
	&& apt-get update \
	&& apt-get install -y postgresql-common \
	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
	&& apt-get install -y \
		gcc \
		git \
		libssl-dev \
		libffi-dev \
		lzop \
		postgresql-$PG_MAJOR=$PG_VERSION \
		postgresql-contrib-$PG_MAJOR=$PG_VERSION \
		pv \
		python \
		python-dev \
		--no-install-recommends \
	&& mkdir -p /var/run/postgresql \
	&& chown -R postgres /var/run/postgresql \
	&& curl -sSL https://raw.githubusercontent.com/pypa/pip/7.1.2/contrib/get-pip.py | python - \
	&& pip install --disable-pip-version-check --no-cache-dir git+https://github.com/deis/wal-e.git@380821a6c4ea4f98a244680d7c6c5b04b8c694b3 \
	&& mkdir -p $WALE_ENVDIR \
	&& pip install --disable-pip-version-check --no-cache-dir envdir \
	&& apt-get remove -y --auto-remove --purge \
		gcc \
		git \
		libssl-dev \
		libffi-dev \
		python-dev \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
