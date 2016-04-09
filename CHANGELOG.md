### 2.0.0-alpha -> v2.0.0-beta1

#### Features

 - [`44f6cfe`](https://github.com/deis/postgres/commit/44f6cfe258c2438cf83635b4bef910119b7b8d99) postgres: run periodic backups in the background
 - [`ac4b163`](https://github.com/deis/postgres/commit/ac4b1639059e6b0fe02faa84b9e43531b7656476) create_bucket: raise client error if status code != 404
 - [`b59fccf`](https://github.com/deis/postgres/commit/b59fccf3880050c353da9e6b90e67d5bd96bdfef) contrib: add back integration tests
 - [`3615256`](https://github.com/deis/postgres/commit/3615256d8d86ab233253f59257e052863cfa0e7e) postgres: install wal-e for continuous backups
 - [`b91db20`](https://github.com/deis/postgres/commit/b91db20ec3cfbc25cce644526c949e082cd90cd8) .travis.yml: have this job notify its sister job in Jenkins

#### Fixes

 - [`2e95058`](https://github.com/deis/postgres/commit/2e95058318b9c395c134fac39420da166ad02c38) README: revert README template
 - [`dc02898`](https://github.com/deis/postgres/commit/dc02898ef3cc231f0cc4b125f367444a4ab9cab9) rootfs: install wal-e from commit
 - [`f717c24`](https://github.com/deis/postgres/commit/f717c24b28f5fc72dbf8e982d0dcb7e14ba4d0b2) docker-entrypoint-initdb: bump wait timeout
 - [`4aa3808`](https://github.com/deis/postgres/commit/4aa38080f0724244323c926d62fc75ecd7b7dc99) setup-envdir: write only host if port == 80
 - [`16d1362`](https://github.com/deis/postgres/commit/16d13629d72a512b9f99521de2064d5cf0f254b5) docker-entrypoint-initdb.d: fixup envvar evaluation

#### Maintenance

 - [`1bbac54`](https://github.com/deis/postgres/commit/1bbac546ed8682b62cedf0db99048e1b19d469be) Makefile: Use immutable tags
 - [`2c7acd4`](https://github.com/deis/postgres/commit/2c7acd425aae8427e98863b43e08ba2c7495639a) release: bump version to v2-beta

### 2.0.0-alpha

#### Documentation

 - [`1334843`](https://github.com/deis/postgres/commit/133484310c213a244f6c0d0759948d62de6bddab) readme: change pod name

#### Maintenance

 - [`8f15367`](https://github.com/deis/postgres/commit/8f153673bc4353241604bf442ad9a9fd4307856b) release: set version and lock to deis registry
 - [`2a3fea3`](https://github.com/deis/postgres/commit/2a3fea33624d43c7f432b103554f5b07f92b88c9) deploy.sh: adhere to standard location
