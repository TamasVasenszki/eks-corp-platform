module "vpc" {
  source       = "./modules/vpc_network"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
}