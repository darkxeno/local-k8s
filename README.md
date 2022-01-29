

Requirements
============

The following tools / software are required in order to succesfully configure your local minikube cluster and deploy the applications.

- Operative System: MacOS
- Terraform CLI
- Git
- Brew
- Docker 

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


# to see all the resources that are going to be created
terraform plan 


# to perform the changes show on the previous command
terraform apply
```


Custom environment configuration
================================

Disclaimer: please only apply per environment configuration changes when there are mayor reasons that justify the decission.

Specific infrastructure changes per environment are enabled on terrafom by using the local.env objects located on the ./terraform/main.tf file.

Default values are defined under local.env.default and can be overriden by using for example local.env.prod for production environment configuration. The selection of the current environment is based on the terraform selected workspace name (see quick start guide).


Specific application deployment changes per environment follow as similar pattern but using helm value files. Default helm values can be found on 
./terraform/modules/deploy-services-with-helm/helm-chart/values/values-default.yaml and can be overriden using the files located on the same folder,
for example values-prod.yaml for defining specific production configuration.

Remember that none of the configuration possibilities explained above should be used to store secrets, for those a secret management system like Hashicorp Vault or the corresponding cloud service provider are recommended (Azure KeyVault, AWS Secrets Manager, ...).


Scalability and Geografically distributed availability
======================================================

For general scalability of the system 3 areas need to be covered:

- Autoscaling of the K8S nodes
- Autoscaling of the K8S deployments
- Scaling of the rabbitmq broker

For geografically distributed availabily the following subjects needs to be addresed:

- Stateless distributions of messages
- Coordinated multiregion deployments
- Geografically distributed DNS resolution (lowest latency region first)


General feedback
================



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