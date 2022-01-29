

Requirements
============

The following tools / software are required in order to succesfully configure your local minikube cluster and deploy the applications.

- Operative System: MacOS (support to additional OSs is part of the roadmap)
- Terraform CLI
- Brew
- Docker (replacement by Lime is part of the roadmap)

Quick Start
===========




Notes
=====

After a succesfully execution of the terraform scripts, and to continue using them to manage your local minukube cluster, starting the minikube
service could be required, for that use the following command:

```
minikube start
```

Otherwise errors like the following will show up:

```
terraform apply
...
...
...
Error: Get "https://127.0.0.1:58082/api/v1/namespaces/dev": dial tcp 127.0.0.1:58082: connect: connection refused
...
...
```