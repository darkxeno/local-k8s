terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

data "external" "git_commit_id" {
  program = ["bash", "${path.module}/get_sha.sh"]
}

data "external" "git_branch" {
  program = ["bash", "${path.module}/get_branch.sh"]
}

locals {
  commit_id = data.external.git_commit_id.result.sha
  branch = data.external.git_branch.result.branch  
  registry = "localhost:5000"
  engine_tag = "${local.registry}/engine:${local.branch}-${local.commit_id}"
  user_interface_tag = "${local.registry}/user_interface:${local.branch}-${local.commit_id}"
  label = {
    author : "Constantino Fernandez Traba"
    revision: "V2"
  }
  
}

/*
  pull_triggers = [ 
    sha1(file("${path.module}/engine/Dockerfile")),
    sha1(file("${path.module}/engine/engine.py")),
    sha1(file("${path.module}/engine/requirements.txt")),
  ]
  pull_triggers = [ 
    sha1(file("${path.module}/user_interface/Dockerfile")),
    sha1(file("${path.module}/user_interface/user_interface.py")),
    sha1(file("${path.module}/user_interface/requirements.txt")),
  ] 
*/

resource "docker_image" "engine" {
  name = "engine"

  build {
    path = "${path.module}/engine"
    tag  = [local.engine_tag, "${local.registry}/engine:${local.branch}-latest"]
    build_arg = { }
    label = local.label
  }
}


resource "docker_image" "user_interface" {
  name = "user_interface"
 
  build {
    path = "${path.module}/user_interface"
    tag  = [local.user_interface_tag, "${local.registry}/user_interface:${local.branch}-latest"]
    build_arg = { }
    label = local.label
  }
}