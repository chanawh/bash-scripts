from confluent_kafka import Consumer
import json

# Kafka configuration
conf = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'test-group',
    'auto.offset.reset': 'earliest'
}

# Create Consumer instance
consumer = Consumer(conf)
consumer.subscribe(['my-topic'])

print("Listening for messages on 'my-topic'...")

try:
    while True:
        msg = consumer.poll(1.0)
        if msg is None:
            continue
        if msg.error():
            print(f"Consumer error: {msg.error()}")
            continue
        data = json.loads(msg.value().decode('utf-8'))
        print("Received:", data)
except KeyboardInterrupt:
    pass
finally:
    consumer.close()
