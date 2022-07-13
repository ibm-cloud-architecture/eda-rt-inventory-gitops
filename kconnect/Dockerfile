#FROM cp.icr.io/cp/ibm-eventstreams-kafka:10.4.0-kafka-2.8.0
FROM cp.icr.io/cp/ibm-eventstreams-kafka:11.0.2
# FROM debezium/connect
COPY ./my-plugins/ /opt/kafka/plugins/
# COPY ./my-plugins/ /kafka/libs/
USER 1001
EXPOSE 8080
