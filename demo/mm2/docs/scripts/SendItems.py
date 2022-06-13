from confluent_kafka import Producer, KafkaError
from datetime import datetime
import json, os, sys
import random

'''
This is a basic python code to generate random items events and send them to kafka.
This is a good scenario for sharing reference data
'''
KAFKA_BROKERS = os.getenv('KAFKA_BROKERS')
KAFKA_CERT = os.getenv('KAFKA_CERT','')
KAFKA_USER =  os.getenv('KAFKA_USER','')
KAFKA_PWD =  os.getenv('KAFKA_PWD','')
KAFKA_SASL_MECHANISM=  os.getenv('KAFKA_SASL_MECHANISM','')
KAFKA_SECURITY_PROTOCOL= os.getenv('KAFKA_SECURITY_PROTOCOL','')
SOURCE_TOPIC = os.getenv('TOPIC','items')

options ={
    'bootstrap.servers': KAFKA_BROKERS,
    'client.id': 'ItemsProducer',
    'delivery.timeout.ms': 15000,
    'request.timeout.ms' : 15000
}

if (KAFKA_SECURITY_PROTOCOL != ''):
    options['security.protocol'] = KAFKA_SECURITY_PROTOCOL
if (KAFKA_SASL_MECHANISM != ''):
    options['sasl.mechanisms'] = KAFKA_SASL_MECHANISM
    options['sasl.username'] = KAFKA_USER
    options['sasl.password'] = KAFKA_PWD

if (KAFKA_CERT != '' ):
    options['ssl.ca.location'] = KAFKA_CERT
    

producer=Producer(options)


def delivery_report(err, msg):
        """ Called once for each message produced to indicate delivery result.
            Triggered by poll() or flush(). """
        if err is not None:
            print('[ERROR] - [KafkaProducer] - Message delivery failed: {}'.format(err))
        else:
            print('[KafkaProducer] - Message delivered to {} [{}]'.format(msg.topic(), msg.partition()))

def publishEvent(topicName, products):
    dataStr = ''
    try:
        for p in products:
            print(p)
            dataStr = json.dumps(p).encode('utf-8')
            producer.produce(topicName,
                key=p["id"],
                value=dataStr, 
                callback=delivery_report)
    except Exception as err:
        print('Failed sending message {0}'.format(dataStr))
        print(err)
    producer.flush()
    

def generateProducts(nb_record):
    products = []
    for i in range(0,nb_records):
        p = { "id": "I" + str(i+1), "price": round(random.uniform(33.33, 66.66), 2) , "quantity": random.randint(1,100) ,"sku": "Item_" + str(random.randint(1,100)) ,"storeName":"Store_" + str(random.randint(1,5)),"timestamp": datetime.today().strftime('%Y-%m-%dT%H:%M:%S.%f'), "type":"SALE"}      
        products.append(p)
    return products

def signal_handler(sig,frame):
    producer.close()
    sys.exit(0)

def parseArguments():
    nb_records = 0
    if len(sys.argv) < 2:
        sys.exit("Error - Usage: python SendItems.py [number_of_records]")
    else:
        nb_records=int(sys.argv[1])
        
    return nb_records

if __name__ == "__main__":
    nb_records = parseArguments()
    if (nb_records > 0):
        products = generateProducts(nb_records)
    try:
        print("--- This is the configuration for the producer: ---")
        print('[KafkaProducer] - {}'.format(options))
        print("---------------------------------------------------")        
        publishEvent(SOURCE_TOPIC,products)
    except KeyboardInterrupt:
        producer.close()
        sys.exit(0)
    
