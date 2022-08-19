# [Real time inventory demo GitOps](https://ibm-cloud-architecture.github.io/eda-rt-inventory-gitops)

See [Mkdocs book view](https://ibm-cloud-architecture.github.io/eda-rt-inventory-gitops) to get demonstration script and installation.

This project can let you deploy the real-time inventory demonstration on OpenShift or run it locally on your laptop using docker compose.
For OpenShift deployment you can

- Use an existing Event Streams deployed (multi-tenants) in `cp4i-eventstreams` namesspace, the topic is using a naming convention to avoid conflicting with other topics alreadt defined in this cluster.
- Use this repository to deploy a 3 broker cluster in the `rt-inventory-dev` namespace

To deploy you can use a pure GitOps approach using OpenShift GitOps or use `make` to deploy with `oc CLI` (See the Makefile under the root folder). 

Be sure to clone this repository

```sh
git clone https://github.com/ibm-cloud-architecture/eda-rt-inventory-gitops.git
```

## Run locally

* Start IBM Event Streams, IBM MQ, Kafka Connector, the Store Simulator App, the Item aggregator App, the Store aggregator App, and KafDrop to get a user interface to Kafka

```sh
cd local-demo/kstreams
docker-compose up -d
```

* Should have following docker containers running


```sh
docker ps
# output
IMAGE                                             PORTS                                          NAMES
   cp.icr.io/cp/ibm-eventstreams-kafka:11.0.2                                                    kstreams-addTopics-1
   quay.io/ibmcase/item-aggregator              0.0.0.0:8081->8080/tcp                           item-aggregator
   quay.io/ibmcase/eda-kconnect-cluster-image   8080/tcp, 0.0.0.0:8083->8083/tcp                 kconnect
   obsidiandynamics/kafdrop                     0.0.0.0:9000->9000/tcp                           kafdrop
   quay.io/ibmcase/store-aggregator             0.0.0.0:8082->8080/tcp                           store-aggregator
   cp.icr.io/cp/ibm-eventstreams-kafka:11.0.2   0.0.0.0:9092->9092/tcp, 0.0.0.0:29092->9092/tcp  kafka
   cp.icr.io/cp/ibm-eventstreams-kafka:11.0.2   0.0.0.0:2181->2181/tcp                           zookeeper
   ibmcom/mq                                    0.0.0.0:1414->1414/tcp, 0.0.0.0:9157->9157/tcp, 0.0.0.0:9443->9443/tcp   ibmmq
```

See the [demonstration script explanation](https://ibm-cloud-architecture.github.io/eda-rt-inventory-gitops/#run-the-solution-locally) specific to running locally.

## Deploy yo OpenShift

### Using existing Event Streams in multi-tenant

```sh
make multi_tenants
```

The trace for the execution will looks like:

```
amespace/rt-inventory-dev created
serviceaccount/rt-inv-job-sa created
role.rbac.authorization.k8s.io/secret-mgr created
rolebinding.rbac.authorization.k8s.io/rt-inventory-dev-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/secrets-to-sa created
job.batch/cpsecret created
Now using project "rt-inventory-dev" on server "https://api.rey.coc-ibm.com:6443".
job.batch/cp-ca-secret created
job.batch/cp-tls-usr-secret created
job.batch/cp-scram-usr-secret created
kafkatopic.eventstreams.ibm.com/eda-rt-item.inventory created
kafkatopic.eventstreams.ibm.com/eda-rt-items created
kafkatopic.eventstreams.ibm.com/eda-rt-store.inventory created
kafkauser.eventstreams.ibm.com/eda-scram-user created
kafkauser.eventstreams.ibm.com/eda-tls-user created
configmap/mq-config created
configmap/mq-mqsc-config created
queuemanager.mq.ibm.com/store-mq created
kafkaconnect.eventstreams.ibm.com/eda-connect-cluster created
kafkaconnector.eventstreams.ibm.com/mq-source created
serviceaccount/store-simulator created
rolebinding.rbac.authorization.k8s.io/store-simulator-view created
configmap/store-simulator-cm created
service/store-simulator created
deployment.apps/store-simulator created
route.route.openshift.io/store-simulator created
serviceaccount/store-inventory created
rolebinding.rbac.authorization.k8s.io/store-inventory-view created
configmap/store-inventory-cm created
service/store-aggregator created
deployment.apps/store-aggregator created
route.route.openshift.io/store-aggregator created
serviceaccount/item-inventory created
rolebinding.rbac.authorization.k8s.io/item-inventory-view created
configmap/item-inventory-cm created
service/item-inventory created
deployment.apps/item-inventory created
route.route.openshift.io/item-inventory created
```

To remove the deployments do:

```sh
make clean_multi_tenants
```


### Deploying Event Streams in the demo project: rt-inventory-dev

```sh
```
## List of related projects:

* [A simulator app to send store event: refarch-eda-store-simulator](https://github.com/ibm-cloud-architecture/refarch-eda-store-simulator)
* [Compute store inventory: refarch-eda-store-inventory](https://github.com/ibm-cloud-architecture/refarch-eda-store-inventory)
* [Compute item inventory cross store: refarch-eda-item-inventory](https://github.com/ibm-cloud-architecture/refarch-eda-item-inventory)