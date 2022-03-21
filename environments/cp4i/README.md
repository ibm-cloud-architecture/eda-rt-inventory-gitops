# Deploy on Existing CP4I cluster

This environment is when you want to deploy this solution on an existing IBM Cloud Pak for Integration demo environment, where Operators and Operandes are in the same namespace, which should be `cp4i`.

## Verify pre-requisites

In this case we assume the following commands will show the prerequisites are ready:

```sh
oc project cp4i
oc get operators 
# Reulsts
aspera-hsts-operator.cp4i
couchdb-operator.cp4i
datapower-operator.cp4i
ibm-ai-wmltraining.cp4i
ibm-apiconnect.cp4i
ibm-appconnect.cp4i
ibm-automation-core.cp4i
ibm-cert-manager-operator.ibm-common-services
ibm-cloud-databases-redis-operator.cp4i
ibm-common-service-operator.cp4i
ibm-common-service-operator.ibm-common-services
ibm-commonui-operator-app.ibm-common-services
ibm-eventstreams.cp4i
ibm-iam-operator.ibm-common-services
ibm-ingress-nginx-operator-app.ibm-common-services
ibm-integration-asset-repository.cp4i
ibm-integration-operations-dashboard.cp4i
ibm-integration-platform-navigator.cp4i
ibm-management-ingress-operator-app.ibm-common-services
ibm-mongodb-operator-app.ibm-common-services
ibm-monitoring-grafana-operator-app.ibm-common-services
ibm-mq.cp4i
ibm-namespace-scope-operator.ibm-common-services
ibm-odlm.ibm-common-services
ibm-platform-api-operator-app.ibm-common-services
ibm-zen-operator.ibm-common-services
openshift-gitops-operator.openshift-operators
openshift-pipelines-operator-rh.openshift-operators
```

## Verify Event Streams bootstrap

* bootstrap URL

```sh
oc get svc | grep bootstrap
```

* Verify existing kafka users

```sh
oc get kafkausers
```

* Verify schema registry URL

```sh

```

## Prepare demo event streams elements

### Create topic

```sh
oc apply -f environments/cp4i/services/ibm-eventstreams/base/topics.yaml
# verify topic ae ready
oc get kafkatopics 
# Results
NAME                                                           CLUSTER   PARTITIONS   REPLICATION FACTOR   READY
consumer-offsets---84e7a678d08f4bd226872e5cdd4eb527fadc1c6a    es-demo   50           1                    True
rt-demo.item.inventory                                         es-demo   1            3                    True
rt-demo.items                                                  es-demo   3            3                    True
rt-demo.store.inventory                                        es-demo   1            3                    True
strimzi-store-topic---effb8e3e057afce1ecf67c3f5d8e4e3ff15      es-demo   1            3                    True
strimzi-topic-operator-kstreams-topic-store-changelog---b75e70 es-demo   1            1                    True
```

If you do not see the topic ready and created in the UI, this is because the topicOperator is not defined in the event stream cluster. Add the following under `strimziOverrides`

```yaml
  strimziOverrides:
    entityOperator:
      topicOperator: {}
      userOperator: {}
```


