variable "environment" {
  type = string
}

variable "docker_engine_tag" {
  type = string
}

variable "docker_user_interface_tag" {
  type = string
}

variable "engine_replicas" {
  type = number
}

variable "user_interface_replicas" {
  type = number
}