from confluent_kafka import Producer
import json

# Kafka configuration
conf = {'bootstrap.servers': 'localhost:9092'}

# Create Producer instance
producer = Producer(conf)

# Data to send
data = {"msg": "Hello from Python producer!"}

# Produce message to topic 'my-topic'
producer.produce('my-topic', value=json.dumps(data).encode('utf-8'))

# Wait for all messages to be delivered
producer.flush()

print("Message sent to Kafka!")
