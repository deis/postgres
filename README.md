# Deis Postgres v2

Deis (pronounced DAY-iss) is an open source PaaS that makes it easy to deploy and manage applications on your own servers. Deis builds on [Kubernetes](http://kubernetes.io/) to provide a lightweight, easy and secure way to deploy your code to production.

For more information about the Deis workflow, please visit the main project page at https://github.com/deis/workflow.

## Beta Status

This Deis component is currently in beta status, and we welcome your input! If you have feedback, please submit an [issue][issues]. If you'd like to participate in development, please read the "Development" section below and submit a [pull request][prs].

# About

This component is a PostgreSQL database for use in Kubernetes. It builds on the official [postgres](https://registry.hub.docker.com/_/postgres/) Docker image. While it's intended for use inside of the Deis open source [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service), it's flexible enough to be used as a standalone pod on any Kubernetes cluster or even as a standlone Docker container.

# Development

The Deis project welcomes contributions from all developers. The high level process for development matches many other open source projects. See below for an outline.

- Fork this repository
- Make your changes
- Submit a [pull request][prs] (PR) to this repository with your changes, and unit tests whenever possible.
- If your PR fixes any [issues][issues], make sure you write Fixes #1234 in your PR description (where #1234 is the number of the issue you're closing)
- The Deis core contributors will review your code. After each of them sign off on your code, they'll label your PR with LGTM1 and LGTM2 (respectively). Once that happens, you may merge.


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
postgres-6wy8o        1/1       Running   0          32s
```

You can then query this pod as you would with any other Kubernetes pod:

```
$ kubectl logs -f postgres-6wy8o
$ kubectl exec -it postgres-6wy8o psql
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

[prs]: https://github.com/deis/postgres/pulls
[issues]: https://github.com/deis/postgres/issues
