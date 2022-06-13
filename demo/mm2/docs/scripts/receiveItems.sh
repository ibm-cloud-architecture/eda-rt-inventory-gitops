#!/bin/bash

export KAFKA_BROKERS=rt-inventory-stg-kafka-bootstrap-rt-inventory-stg.itzroks-665001cc06-wgywnm-4b4a324f027aea19c5cbc0c3275c4656-0000.us-south.containers.appdomain.cloud:443
export KAFKA_USER=rt-inv-stg-user
export KAFKA_PWD=xdCBFtJG7Ye9
export KAFKA_CERT=es-tgt-cert.pem
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_MECHANISM=SCRAM-SHA-512
export SOURCE_TOPIC=items

python3 ReceiveItems.py $1
