#!/bin/bash

export KAFKA_BROKERS=rt-inventory-dev-kafka-bootstrap-rt-inventory-dev.itzroks-4b4a.us-south.containers.appdomain.cloud:443
export KAFKA_USER=rt-inv-dev-user
export KAFKA_PWD=SCRAM-PASSWORD
export KAFKA_CERT=es-src-cert.pem
export KAFKA_SECURITY_PROTOCOL=SASL_SSL
export KAFKA_SASL_MECHANISM=SCRAM-SHA-512
export SOURCE_TOPIC=items

python3 SendItems.py $1
