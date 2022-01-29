terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }       
  }
}


locals {
  nginx_ingress_namespace = "nginx-ingress"
  app_namespace = "${var.environment}"
  default_values = yamldecode(file("${path.module}/helm-chart/values/values-default.yaml"))
  install_helm_and_kubectl_script = <<EOT
    #!/bin/bash 
    set -x
    set -e    

    which kubectl || brew install kubernetes-cli
    which helm || brew install helm
     
  EOT  
}

resource "null_resource" "helm-tools" {

  triggers = {
    script_sha1 = sha1(local.install_helm_and_kubectl_script)
  }

  provisioner "local-exec" {
    command = local.install_helm_and_kubectl_script  
  }
  
}


resource "kubernetes_namespace" "app-namespace" {
  metadata {
    name = local.app_namespace
  }

  depends_on = [ null_resource.helm-tools ]
}

resource "helm_release" "rabbitmq" {
  name       = "rabbitmq"
  
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  version    = "8.27.0"

  namespace = local.app_namespace

  set {
    name  = "service.port"
    value = local.default_values.rabbitmq.port
  } 

  set {
    name  = "auth.password"
    value = var.rabbitmq_password
  }

  set {
    name  = "auth.erlangCookie"
    value = var.rabbitmq_password
  }     

  depends_on = [ kubernetes_namespace.app-namespace ]
}


resource "helm_release" "message-app" {
  name       = "message-app"
  chart      = "${path.module}/helm-chart"

  namespace = local.app_namespace

  values = [
    "${file("${path.module}/helm-chart/values/values-default.yaml")}",
    "${file("${path.module}/helm-chart/values/values-${var.environment}.yaml")}"
  ]

  set {
    name  = "engine.image.tag"
    value = replace(var.docker_engine_tag, "/^.*:/", "")
  }

  set {
    name  = "engine.replicas"
    value = var.engine_replicas
  }   

  set {
    name  = "userInterface.image.tag"
    value = replace(var.docker_user_interface_tag, "/^.*:/", "")
  }

  set {
    name  = "userInterface.replicas"
    value = var.user_interface_replicas
  }

  set {
    name  = "rabbitmq.auth.password"
    value = var.rabbitmq_password
  }  

  set {
    name  = "revision"
    value = "v4-${timestamp()}"
  }    

  depends_on = [ helm_release.rabbitmq ]
 
}
