

/* 
  specific environment config (per terraform workspace)
  please be aware that specific environment config are not recommended
  should only be considered when mayor causes justify them (billing, dependencies, ...)
*/
locals {
   env = {
      default = {
      }
      dev = {
      }
      qa = {         
      }
      uat = {         
      }      
      preprod = {
      }
      prod = {
      }
   }
   environment = contains(keys(local.env), terraform.workspace) ? terraform.workspace : "default"
   // override default with the environment name (worspace name)
   workspace       = "${merge(local.env["default"], local.env[local.environment])}"
}


module "kubernetes-cluster" {
  source = "./modules/kubernetes-cluster"


}

module "build-docker-services" {
  source = "./modules/build-docker-services"


}

module "push-docker-services" {
  source = "./modules/push-docker-services"
  depends_on = [ module.kubernetes-cluster, module.build-docker-services ]

  docker_user_interface_tag = module.build-docker-services.docker_user_interface_tag
  docker_engine_tag = module.build-docker-services.docker_engine_tag

}

module "deploy-services-with-helm" {
  source = "./modules/deploy-services-with-helm"
  depends_on = [ module.push-docker-services ]

  environment = local.environment

}