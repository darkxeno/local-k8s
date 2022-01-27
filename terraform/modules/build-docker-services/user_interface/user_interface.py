import uuid
import json
import random
import pika
import logging
import time
import os
import configparser
from pathlib import Path


# CONST
EXCHANGE = "job-exchange"
EXCHANGE_TYPE = "direct"
JOB_ROUTING_KEY = "job"
RESULT_ROUTING_KEY = "result"
SERVICE_NAME = "user-interface"
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
    logger.info("user got result [{body}] back from "
                f"route [{method.routing_key}]")
    raise DoneConsuming("got result, end consume")


"""
user -> x -> engine
"""
job_emit_connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host=BROKER_HOST,
        port=BROKER_PORT
    )
)
job_emit_channel = job_emit_connection.channel()
job_emit_channel.exchange_declare(
    exchange=EXCHANGE,
    exchange_type=EXCHANGE_TYPE
)

"""
user <- x <- engine
"""
await_result_connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host=BROKER_HOST,
        port=BROKER_PORT
    )
)
await_result_channel = await_result_connection.channel()
await_result_channel.exchange_declare(
    exchange=EXCHANGE,
    exchange_type=EXCHANGE_TYPE
)
result = await_result_channel.queue_declare(queue='', exclusive=True)
await_result_queue_name = result.method.queue

while True:
    message_content = {
        "job_id": str(uuid.uuid4()),
        "job_payload": {
            "type": "integer",
            "value": random.randint(1, 25)
        }
    }
    message = json.dumps(message_content)
    job_emit_channel.basic_publish(
        exchange=EXCHANGE,
        routing_key=JOB_ROUTING_KEY,
        body=message
    )
    logger.info(f"sent [{message}] to x [{EXCHANGE}] via [{JOB_ROUTING_KEY}]")
    logger.info(f"awaiting reply after "
                f"[{message_content['job_payload']['value']}]s")

    await_result_channel.queue_bind(
        exchange=EXCHANGE,
        queue=await_result_queue_name,
        routing_key=RESULT_ROUTING_KEY
    )
    await_result_channel.basic_consume(
        queue=await_result_queue_name,
        on_message_callback=callback,
        auto_ack=True
    )
    try:
        await_result_channel.start_consuming()
    except DoneConsuming as e:
        logging.error(f"got [{str(e)}] from queue - ending consume")
        await_result_channel.stop_consuming()

    logger.info("take a break, you've earned it")
    time.sleep(1)

await_result_connection.close()
job_emit_connection.close()

