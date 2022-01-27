
locals {
  install_minikube_script = <<EOT
    #!/bin/bash 
    set -x
    set -e    

    brew install minikube

    which minikube || $(brew unlink minikube; brew link minikube)

    minikube start

  EOT  
  install_minikube_addons_script = <<EOT
    #!/bin/bash 
    set -x
    set -e    

    #minikube addons enable registry

    #docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"

    minikube addons enable ingress 

  EOT   
}

resource "null_resource" "minikube" {

  triggers = {
    script_sha1 = sha1(local.install_minikube_script)
  }

  provisioner "local-exec" {
    command = local.install_minikube_script
    environment = {

    }    
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      #!/bin/bash 
      set -x
      set -e    

      brew remove --force minikube

    EOT      
  }

}

resource "null_resource" "minikube-addons" {

  triggers = {
    script_sha1 = sha1(local.install_minikube_addons_script)
  }

  provisioner "local-exec" {
    command = local.install_minikube_addons_script
  }

  depends_on = [ null_resource.minikube ] 
}