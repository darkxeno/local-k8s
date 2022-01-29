# DEV-OPS CHALLENGE

## Introduction
The purpose of this task is to introduce you, the candidate, to a piece of
architecture and ask you to create an automated deployment given the building
blocks which we have provided. 

There is no right/wrong way of creating a submission for this task and
we encourage you to submit working code which showcases your ability to take
software components and turn them into an automated deployment which we could
try out ourselves using i.e. `minikube`.
We highly appreciate any feedback or critique, especially about elements
that you think are outside the scope/time-frame of this challenge, because such
topics will be perfect starting points for further discussion in the review
session.
 
There are essentially three components to this challenge. 
The `user-interface`, the `message-broker` and the `engine`.Let's discuss
each in more detail. 

### user-interface
The `user-interface` is a simple Python service which is tasked with
connecting to a `message-broker`, subscribing to a `job` channel and subsequently
publishing `jobs` on this channel by sending messages to the `message-broker`.
The `user-interface` also subscribes to a `result` channel and awaits a response
in the form of a message indicating that a `job` has been completed.
In the terminology of pub/sub `user-interface` is both a
producer and a consumer, using a message broker's exchange for communication.

```
.
├── README.md
└── services
	...
    └── user_interface
        ├── Dockerfile # used to build functioning image
        ├── config.ini # note connection parameters stored here
        ├── user_interface.py # source code
        └── requirements.txt # python requirements
```

### engine
Next we have the `engine`. This is yet another simple Python service which
is tasked with connecting to the `message-broker`, subscribing to the `job`
channel and subsequently awaiting incoming messages or `jobs`. This service
also subscribes to the `result` channel and once it has completed a `job`,
it publishes a message here to indicate that the `job` was successfully completed.
In the terminology of pub/sub, `engine` is both a producer and a consumer,
using a message broker's exchange for communication.

```
.
├── README.md
└── services
    ├── engine
    │   ├── Dockerfile # used to build functioning image
    │   ├── config.ini # note connection parameters stored here
    │   ├── engine.py # source code
    │   └── requirements.txt # python requirements
    └── ...
```

### message-broker
Finally, the `message-broker`. This is currently handled by
[RabbitMQ](https://www.rabbitmq.com/) a powerful and established message broker.
Both the `user-interface` and `engine` are configured to use it.
A functioning Docker image can be found [here](https://hub.docker.com/_/rabbitmq).

## Instructions / expectations

 - Build all the necessary Docker images and get them running together in a
 small development cluster using i.e. `minikube`
 
 - Identify and automate steps in the the deployment. Consider configuration,
 code changes and challenges which may arise in a multi-environment setup
 (i.e. dev, staging, production)
 
 - Consider and document how this setup might scale and what further challenges
 may arise in managing this deployment across multiple geographical locations
 
 - Consider and document critique and feel free to propose alternatives
 and/or improvements

