# Kafka connect configuration and images for elastic search and cloud object storage sinks

## Update the custom image

```sh
cd src
IMAGE_NAME=quay.io/ibmcase/eda-kconnect-cluster-image 
TAG=latest
docker build -t ${IMAGE_NAME}:${TAG} .
docker push ${IMAGE_NAME}:${TAG}
```

## Deploy the Kafka connect cluster

```sh
oc apply -f kafka-connect.yaml
# Verify cluster is ready
oc get kafkaconnect
```