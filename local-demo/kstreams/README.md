# Deploy the RT inventory locally

This is an example of running the solution using Docker compose.

## With Docker desktop and docker compose

If you have Docker Desktop license you can use the docker compose in this folder.

* be sure to have allocated enough docker resource: `4 CPUs, 9 GB RAM, Swap: 1 GB`
* If using Cloud Object Storage as a sink for the store.inventory modify the `../kconnect/kafka-cos-sink-standalone.properties` file with your COS credentials, something like

```
cos.api.key=X3Yde....sQZ3
cos.bucket.location=us-east
cos.bucket.name=eda-demo
cos.bucket.resiliency=regional
cos.service.crn="crn:v1:b.....l:a/ecdc......32a6c8e4::"
```

* Run the complete solution with:

```sh
docker-compose up -d
# Verify containers are running
docker ps | awk 'print $2|'
quay.io/ibmcase/item-aggregator
quay.io/ibmcase/eda-store-simulator
obsidiandynamics/kafdrop
quay.io/ibmcase/store-aggregator
cp.icr.io/cp/ibm-eventstreams-kafka:10.5.0
cp.icr.io/cp/ibm-eventstreams-kafka:10.5.0
ibmcom/mq
```

* [Optional] Verify topics exist (They should have been created by dockercompose pod)

```sh
./listTopics.sh
# The output should looks like:
######################
 List Topics
__consumer_offsets
item-aggregator-ItemStock-changelog
item-aggregator-ItemStock-repartition
item.inventory
items
store-aggregator-StoreInventoryStock-changelog
store.inventory
```

* Execute basic demo script as described in [this note]()

    1. Go to the simulator UI

        ```sh
        chrome http://localhost:8080/
        ```

    1. Go to IBM MQ console to verify messages in Queue, with user: admin/passw0rd

        ```sh
         chrome https://localhost:9443  
        ```

        You may not see the messages if they were already consumed by the Kafka Connector

    1. Verify messages are in the items topics

         ```sh
        chrome http://localhost:9000/
        ```