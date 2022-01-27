FROM python:3.9-alpine

WORKDIR /home/worker/service
RUN adduser -s /bin/bash -h /home/worker/ worker -D

COPY --chown=worker:worker requirements.txt .
RUN pip3 install --requirement requirements.txt --no-cache-dir --user

ENV PYTHONPATH /home/worker/service
COPY --chown=worker:worker config.ini .
COPY --chown=worker:worker engine.py .

ENTRYPOINT ["python3"]
CMD ["-u", "engine.py"]

