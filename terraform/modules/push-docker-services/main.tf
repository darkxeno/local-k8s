
locals {
  load_images_to_minikube_script = <<EOT
    #!/bin/bash 
    set -x
    set -e    

    minikube image load ${var.docker_engine_tag}
    minikube image load ${var.docker_user_interface_tag}
     
  EOT  
}

resource "null_resource" "minikube" {

  triggers = {
    script_sha1 = sha1(local.load_images_to_minikube_script)
  }

  provisioner "local-exec" {
    command = local.load_images_to_minikube_script  
  }
  
}