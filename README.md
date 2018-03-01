
|![](https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Warning.svg/156px-Warning.svg.png) | Deis Workflow is no longer maintained.<br />Please [read the announcement](https://deis.com/blog/2017/deis-workflow-final-release/) for more detail. |
|---:|---|
| 09/07/2017 | Deis Workflow [v2.18][] final release before entering maintenance mode |
| 03/01/2018 | End of Workflow maintenance: critical patches no longer merged |
| | [Hephy](https://github.com/teamhephy/workflow) is a fork of Workflow that is actively developed and accepts code contributions. |

# Deis Postgres

[![Build Status](https://ci.deis.io/job/postgres/badge/icon)](https://ci.deis.io/job/postgres)
[![Docker Repository on Quay](https://quay.io/repository/deis/postgres/status "Docker Repository on Quay")](https://quay.io/repository/deis/postgres)

Deis (pronounced DAY-iss) Workflow is an open source Platform as a Service (PaaS) that adds a developer-friendly layer to any [Kubernetes](http://kubernetes.io) cluster, making it easy to deploy and manage applications on your own servers.

For more information about the Deis Workflow, please visit the main project page at https://github.com/deis/workflow.

We welcome your input! If you have feedback, please submit an [issue][issues]. If you'd like to participate in development, please read the "Development" section below and submit a [pull request][prs].

# About

This component is a PostgreSQL database for use in Kubernetes. It builds on the official [postgres](https://registry.hub.docker.com/_/postgres/) Docker image. While it's intended for use inside of the Deis Workflow open source [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service), it's flexible enough to be used as a standalone pod on any Kubernetes cluster or even as a standalone Docker container.

# Development

The Deis project welcomes contributions from all developers. The high level process for development matches many other open source projects. See below for an outline.

- Fork this repository
- Make your changes
- Submit a [pull request][prs] (PR) to this repository with your changes, and unit tests whenever possible
- If your PR fixes any [issues][issues], make sure you write Fixes #1234 in your PR description (where #1234 is the number of the issue you're closing)
- The Deis core contributors will review your code. After each of them sign off on your code, they'll label your PR with LGTM1 and LGTM2 (respectively). Once that happens, a contributor will merge it

## Prerequisites

In order to develop and test this component in a Deis cluster, you'll need the following:

* [GNU Make](https://www.gnu.org/software/make/)
* [Docker](https://www.docker.com/) installed, configured and running
* A working Kubernetes cluster and `kubectl` installed and configured to talk to the cluster
 * If you don't have this setup, please see [the Kubernetes documentation][k8s-docs]

## Testing Your Code

Once you have all the aforementioned prerequisites, you are ready to start writing code. Once you've finished building a new feature or fixed a bug, please write a unit or integration test for it if possible. See [an existing test](https://github.com/deis/postgres/blob/master/contrib/ci/test.sh) for an example test.

If your feature or bugfix doesn't easily lend itself to unit/integration testing, you may need to add tests at a higher level. Please consider adding a test to our [end-to-end test suite](https://github.com/deis/workflow-e2e) in that case. If you do, please reference the end-to-end test pull request in your pull request for this repository.

### Dogfooding

Finally, we encourage you to [dogfood](https://en.wikipedia.org/wiki/Eating_your_own_dog_food) this component while you're writing code on it. To do so, you'll need to build and push Docker images with your changes.

This project has a [Makefile](https://github.com/deis/postgres/blob/master/Makefile) that makes these tasks significantly easier. It requires the following environment variables to be set:

* `DEIS_REGISTRY` - A Docker registry that you have push access to and your Kubernetes cluster can pull from
  * If this is [Docker Hub](https://hub.docker.com/), leave this variable empty
  * Otherwise, ensure it has a trailing `/`. For example, if you're using [Quay.io](https://quay.io), use `quay.io/`
* `IMAGE_PREFIX` - The organization in the Docker repository. This defaults to `deis`, but if you don't have access to that organization, set this to one you have push access to.
* `SHORT_NAME` (optional) - The name of the image. This defaults to `postgres`
* `VERSION` (optional) - The tag of the Docker image. This defaults to the current Git SHA (the output of `git rev-parse --short HEAD`)

Assuming you have these variables set correctly, run `make docker-build` to build the new image, and `make docker-push` to push it. Here is an example command that would push to `quay.io/arschles/postgres:devel`:

```console
export DEIS_REGISTRY=quay.io/
export IMAGE_PREFIX=arschles
export VERSION=devel
make docker-build docker-push
```

Note that you'll have to push your image to a Docker repository (`make docker-push`) in order for your Kubernetes cluster to pull the image. This is important for testing in your cluster.


[issues]: https://github.com/deis/postgres/issues
[k8s-docs]: http://kubernetes.io/docs
[prs]: https://github.com/deis/postgres/pulls
[v2.18]: https://github.com/deis/workflow/releases/tag/v2.18.0
