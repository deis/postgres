# Postgres

A PostgreSQL database for use in the [Deis](http://deis.io) open source PaaS.

This Docker image is based on the official
[postgres](https://registry.hub.docker.com/_/postgres/) image.

Master/slave replication and leader election code is largely inspired by [`compose/governor`](https://github.com/compose/governor).

Please add any [issues](https://github.com/deis/postgres/issues) you find with this software.


## Deploying

In order to run this component in Kubernetes, a few prerequisites are needed:

 - An AWS account with S3 enabled
 - An external etcd cluster
 - your own kubernetes cluster

In Deis, these services are provided to you automatically through [the store](http://docs.deis.io/en/latest/understanding_deis/components/#store)
and [etcd](https://github.com/technosophos/etcd) components.

To build a dev release of this image, you will also need your own registry, but DockerHub or
[Quay](https://quay.io/) will do fine here. To build, run:

```bash
$ make build
$ docker build -t deis/postgres:v0.0.1
$ docker push deis/postgres:v0.0.1
```

This will compile the Docker image and push it to your registry.

Then, you'll need to modify the kubernetes manifests to point to your S3 account and your etcd
cluster. Open up the replication controller manifest and change the values:

```
$ git diff
diff --git a/manifests/postgres-rc.json b/manifests/postgres-rc.json
index a5cbb23..70d3bc2 100644
--- a/manifests/postgres-rc.json
+++ b/manifests/postgres-rc.json
@@ -22,15 +22,15 @@
         "containers": [
           {
             "name": "deis-database",
-            "image": "CHANGEME",
+            "image": "deis/postgres:v0.0.1",
             "env": [
               {
                 "name" : "AWS_ACCESS_KEY_ID",
-                "value" : "CHANGEME"
+                "value" : "FOO"
               },
               {
                 "name" : "AWS_SECRET_ACCESS_KEY",
-                "value" : "CHANGEME"
+                "value" : "BAR"
               },
               {
                 "name" : "WALE_S3_PREFIX",
@@ -38,7 +38,7 @@
               },
               {
                 "name" : "ETCD_SERVICE_HOST",
-                "value" : "192.168.0.1"
+                "value" : "10.0.1.100"
               }
             ],
             "ports": [
```

After that, run

```
$ make deploy
```

Which will deploy the component to kubernetes. After a while, you should see a few pods up with one
running:

```
NAME                  READY     STATUS    RESTARTS   AGE
deis-database-6wy8o   1/1       Running   0          32s
deis-database-rh00d   0/1       Running   0          32s
```

You can then query these images as you would with any other Kubernetes pod:

```
$ kubectl logs -f deis-database-6wy8o
$ kubectl exec -it deis-database-6wy8o psql
```


## Testing

**Note**: At this time, tests from Deis v1 are still being ported over.

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
