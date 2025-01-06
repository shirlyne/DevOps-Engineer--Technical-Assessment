import os
import time
import requests
import logging
from prometheus_client import start_http_server, Gauge
from requests.auth import HTTPBasicAuth

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Define Prometheus metrics
QUEUE_MESSAGES = Gauge('rabbitmq_individual_queue_messages', 'Total count of messages in queue', ['host', 'vhost', 'name'])
QUEUE_MESSAGES_READY = Gauge('rabbitmq_individual_queue_messages_ready', 'Count of ready messages in queue', ['host', 'vhost', 'name'])
QUEUE_MESSAGES_UNACKNOWLEDGED = Gauge('rabbitmq_individual_queue_messages_unacknowledged', 'Count of unacknowledged messages in queue', ['host', 'vhost', 'name'])

# Environment variables
RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'localhost')
RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', '15672'))
RABBITMQ_USER = os.getenv('RABBITMQ_USER', 'guest')
RABBITMQ_PASSWORD = os.getenv('RABBITMQ_PASSWORD', 'guest')
METRICS_PORT = int(os.getenv('METRICS_PORT', 8000))
SCRAPE_INTERVAL = int(os.getenv('SCRAPE_INTERVAL', 60))

API_URL = f'http://{RABBITMQ_HOST}:{RABBITMQ_PORT}/api/queues'

def get_queues():
    try:
        response = requests.get(API_URL, auth=HTTPBasicAuth(RABBITMQ_USER, RABBITMQ_PASSWORD), timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Error connecting to RabbitMQ API: {e}")
        return []

def update_metrics():
    queues = get_queues()
    if not queues:
        return

    for queue in queues:
        try:
            vhost = queue['vhost']
            name = queue['name']
            messages = queue.get('messages', 0)
            messages_ready = queue.get('messages_ready', 0)
            messages_unacknowledged = queue.get('messages_unacknowledged', 0)

            QUEUE_MESSAGES.labels(host=RABBITMQ_HOST, vhost=vhost, name=name).set(messages)
            QUEUE_MESSAGES_READY.labels(host=RABBITMQ_HOST, vhost=vhost, name=name).set(messages_ready)
            QUEUE_MESSAGES_UNACKNOWLEDGED.labels(host=RABBITMQ_HOST, vhost=vhost, name=name).set(messages_unacknowledged)

        except KeyError as e:
            logger.error(f"Missing key in queue data: {e}, Queue Data: {queue}")

def start_exporter():
    start_http_server(METRICS_PORT)
    logger.info(f"Prometheus exporter started on port {METRICS_PORT}")

    while True:
        update_metrics()
        time.sleep(SCRAPE_INTERVAL)

if __name__ == '__main__':
    start_exporter()