import pika
import logging
import time
import json
import os
import configparser
from pathlib import Path


# CONST
EXCHANGE = "job-exchange"
EXCHANGE_TYPE = "direct"
JOB_ROUTING_KEY = "job"
RESULT_ROUTING_KEY = "result"
SERVICE_NAME = "engine"
BROKER_HOST = os.environ.get('BROKER_HOST')
BROKER_PORT = os.environ.get('BROKER_PORT')


# LOGGING
logging.basicConfig(
    format='%(asctime)s %(message)s',
    datefmt='%m/%d/%Y %I:%M:%S %p'
)
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class DoneConsuming(Exception):
    pass


def callback(ch, method, properties, body):
    parsed_body = json.loads(body)
    logger.info(f"engine got job [{parsed_body['job_id']}] "
                f"from route [{method.routing_key}]")
    if parsed_body["job_payload"]["type"] == "integer":
        logger.info("processing...")
        time.sleep(parsed_body["job_payload"]["value"])
    raise DoneConsuming("got job and processed")


"""
user -> x -> engine
"""
job_consume_connection = pika.BlockingConnection(
    pika.ConnectionParameters(host=BROKER_HOST,
                              port=BROKER_PORT)
)
job_consume_channel = job_consume_connection.channel()

job_consume_channel.exchange_declare(
    exchange=EXCHANGE,
    exchange_type=EXCHANGE_TYPE
)
job = job_consume_channel.queue_declare(queue='', exclusive=True)
await_job_queue_name = job.method.queue
job_consume_channel.queue_bind(
    exchange=EXCHANGE,
    queue=await_job_queue_name,
    routing_key=JOB_ROUTING_KEY
)


"""
user <- x <- engine
"""
result_emit_connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host=BROKER_HOST,
        port=BROKER_PORT
    )
)
result_emit_channel = result_emit_connection.channel()
result_emit_channel.exchange_declare(
    exchange=EXCHANGE,
    exchange_type=EXCHANGE_TYPE
)


while True:
    job_consume_channel.basic_consume(
        queue=await_job_queue_name,
        on_message_callback=callback
    )
    try:
        logger.info(f"start consuming from [{await_job_queue_name}] "
                    f"@ [{EXCHANGE}]")
        job_consume_channel.start_consuming()
    except DoneConsuming as e:
        logging.error(f"got [{str(e)}] from queue - ending consume")
        job_consume_channel.stop_consuming()
    message = "job complete"
    result_emit_channel.basic_publish(
        exchange=EXCHANGE,
        routing_key=RESULT_ROUTING_KEY,
        body=message
    )
    logger.info("reply sent")

    logger.info("take a break, you've earned it")
    time.sleep(1)

