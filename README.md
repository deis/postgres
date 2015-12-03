# Postgres

A PostgreSQL database for use in the [Deis](http://deis.io) open source PaaS.

This Docker image is based on the official
[postgres](https://registry.hub.docker.com/_/postgres/) image.

Master/slave replication and leader election code is largely inspired by [`compose/governor`](https://github.com/compose/governor).

Please add any [issues](https://github.com/deis/postgres/issues) you find with this software.


## Deploying

To build a dev release of this image, you will also need your own registry, but DockerHub or
[Quay](https://quay.io/) will do fine here. To build, run:

```bash
$ export DEIS_REGISTRY=myregistry.com:5000
$ make docker-build docker-push
```

This will compile the Docker image and push it to your registry.

After that, run

```
$ make deploy
```

Which will deploy the component to kubernetes. After a while, you should see one pod up with one
running:

```
NAME                  READY     STATUS    RESTARTS   AGE
deis-database-6wy8o   1/1       Running   0          32s
```

You can then query this pod as you would with any other Kubernetes pod:

```
$ kubectl logs -f deis-database-6wy8o
$ kubectl exec -it deis-database-6wy8o psql
```


## Testing

You can run the test suite with

```
$ make test
```


## License

© 2015 Engine Yard, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
