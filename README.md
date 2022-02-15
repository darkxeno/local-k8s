 
 
Requirements
============
 
The following tools / software are required in order to successfully configure your local minikube cluster and deploy the applications.
 
- Operative System: MacOS
- Terraform CLI
- Git
- Brew
- Docker (for Apple Silicon computers please read this: https://docs.docker.com/desktop/mac/apple-silicon/)

There is *no support for ARM architectures* at the moment. For more information on this please check the notes below.
 
Support for additional OSs will be considered for the future, as well as a drop in replacement for docker (Lime) due to licensing changes of the docker desktop application.
 
Quick Start
===========
 
All terraform commands should be launched under the terraform root folder, so first of all let make it our current working directory:
 
```
cd ./terraform
```
 
OPTION A: First time
Create the terraform workspace for your desired environment [default available: dev, qa, uat, preprod, prod].
 
```
terraform workspace new dev
```
 
OPTION B: Next times
Otherwise, if the terraform workspace was already created in the past, select the desired workspace.
 
```
terraform workspace select dev
```
 
Now we are ready to create and provision all our infrastructure and software:
 
```
# to initialize all terraform providers and modules
terraform init
 
 
# to see all the cluster resources that are going to be created
terraform plan -target=module.kubernetes-cluster
 
# first we create the k8s cluster to get the helm and kubernetes provider credentials
terraform apply -target=module.kubernetes-cluster

# now we execute the rest of the modules
terraform apply
```

Finally after finalizing the work with the environment created.

```
terraform destroy
```
 
 
Custom environment configuration
================================
 
Disclaimer: please only apply per environment configuration changes when there are major reasons that justify the decision.
 
Specific infrastructure changes per environment are enabled on terraform by using the local.env objects located on the ./terraform/main.tf file.
 
Default values are defined under local.env.default and can be overridden by using for example local.env.prod for production environment configuration. The selection of the current environment is based on the terraform selected workspace name (see quick start guide).
 
 
Specific application deployment changes per environment follow a similar pattern but using helm value files. Default helm values can be found on ./terraform/modules/deploy-services-with-helm/helm-chart/values/values-default.yaml and can be overridden using the files located on the same folder, for example values-prod.yaml for defining specific production configuration.
 
Remember that none of the configuration possibilities explained above should be used to store secrets, for those a secret management system like Hashicorp Vault or the corresponding cloud service provider are recommended (Azure KeyVault, AWS Secrets Manager, ...).
 
 
Scalability and Geographically distributed availability
======================================================
 
For general scalability of the system at least 3 areas need to be covered:
 
- Autoscaling of the K8S nodes
- Autoscaling of the K8S deployments
- Scaling of the rabbitmq broker
 
Autoscaling of the K8S nodes
----------------------------

Collect general metrics about resource usage of the nodes (CPU, memory, network utilization, start up time, ...) and specific custom metrics using prometheus (messages produced per node, messages consumed per node). Based on the metrics collected and monitoring both under synthetic and organic traffic find the breaking point where the quality of service starts to degrade. Build and test autoscaling policies based on those metrics and the quality breaking point.
 
Consider using the kubernetes autoscaler (https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler), to have more mechanisms to scale the number of nodes of your cluster and to coordinate with the scaling of the deployment pods (below).
 
 
 
Autoscaling of the K8S deployments
---------------------------------- 

Adjust the deployment specification based on initial requirement and observed maximum consumptions. Gather per pod message metrics (consumed, produced). Use the horizontal pod autoscaler or the kubernetes API to scale the number of replicas depending on message metrics.
 
The demand on the number pods will coordinate with the demand of nodes when using the kubernetes autoscaler.
 
 
Scaling of the rabbitmq broker
------------------------------

Scale the number of replicas of the rabbitmq statefulset based on the messages and resource usage metrics (see service.metricsPort and service.metricsPortName https://github.com/bitnami/charts/tree/master/bitnami/rabbitmq).
 
Adjust rabbitmq upon the specific requirements of your services:
 
- Cluster configuration
- Message persistence
- Queue sizes and configuration (delivery guarantees)
- Consider partitioning and cell based organizations
- Monitor, monitor, monitor, change, monitor, monitor, change, ....
 
For all of the above
-------------------- 
Automate the testing of your scaling strategies to ensure being up to date with app requirements, to prepare for capacity planning and to anticipate bottlenecks.
 
Geographically distributed availability
=======================================

For geographically distributed availability at least the following subjects needs to be considered:
 
- Stateless distributions of messages
- Coordinated multi region deployments
- Geographically distributed DNS resolution (lowest latency region first)
 
 
Stateless distributions of messages
-----------------------------------
 
Do our messages need to be geographically distributed? redundant?
Could an organization of the infrastructure in cells or multiple rabbitmq clusters be considered?
What are the implications of a message produced on one region and consumed on another?
Could edge distributed locations be enough for our use cases?
Are our services completely stateless to be distributed?
Are we using authentication and authorization schemes that facilitate stateless distribution / federation?
 
Coordinated multi region deployments
------------------------------------
 
Single region deployments normally only require rolling updates and rollbacks. But multiregion deployments require well parametrized pipelines and give the opportunity to consider more complex deployment strategies like enabling canary releases in one of the regions or to use continuous monitoring to replicate a successful deployment from one region to another. Updates and rollbacks need to be coordinated as well, so cases where a first or are a Nth deployment fail need to be considered, planned and resolved automatically.
 
Geographically distributed DNS resolution
-----------------------------------------
 
In order to obtain the maximum benefit from a geographically distributed service (apart from the additional high availability and capacity), a DNS or routing service should be able to resolve DNS queries or direct traffic to the faster (latency) or more near location.
 
Azure Front Door, Azure Traffic Manager, AWS Route 53 are some of the cloud services that allow to resolve this requirement.
 
 
General feedback
================
 
Found the task proposed interesting, requiring a decent level of creativity and showcasing some of the aptitudes required for the DevOps day to day work.
 
Difficult to stablish a connection between this work using minikube to a real cloud environment in order to respond to the questions about multi-environment and multi-region proposed.
 
Roadmap
=======
 
- Add liveness and readiness (including assessing broker connectivity) health checks using Flask
- Add support for more operative systems
- Replace Docker by Lime
- Add support for more k8s cluster technologies
- Adjust resource specification based on metrics (metrics-server or prometheus)
- Troubleshooting and improvements based on real usage scenarios
 
Notes
=====
 
After a successful execution of the terraform scripts, and to continue using them to manage your local minikube cluster, starting the minikube
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


The bitnami docker images for RabbitMQ doesn't offer support for ARM architectures at the moment. (for example: Apple Silicon computers, M1 arm64): 

https://github.com/bitnami/bitnami-docker-rabbitmq/issues/186

```
kubectl logs rabbitmq-0 -n dev
rabbitmq 08:38:53.48
rabbitmq 08:38:53.51 Welcome to the Bitnami rabbitmq container
rabbitmq 08:38:53.53 Subscribe to project updates by watching https://github.com/bitnami/bitnami-docker-rabbitmq
rabbitmq 08:38:53.56 Submit issues and feature requests at https://github.com/bitnami/bitnami-docker-rabbitmq/issues
rabbitmq 08:38:53.58
rabbitmq 08:38:53.60 INFO  ==> ** Starting RabbitMQ setup **
rabbitmq 08:38:53.79 INFO  ==> Validating settings in RABBITMQ_* env vars..
rabbitmq 08:38:54.02 INFO  ==> Initializing RabbitMQ...
rabbitmq 08:38:54.43 INFO  ==> Starting RabbitMQ in background...
/opt/bitnami/scripts/libos.sh: line 336:   134 Segmentation fault      "$@" > /dev/null 2>&1
/opt/bitnami/scripts/libos.sh: line 336:   232 Segmentation fault      "$@" > /dev/null 2>&1
/opt/bitnami/scripts/libos.sh: line 336:   281 Segmentation fault      "$@" > /dev/null 2>&1
```

If you see error like this on the rabbitMQ logs you are affected by this issue.
