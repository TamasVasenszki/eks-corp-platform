module "vpc" {
  source       = "./modules/vpc_network"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = var.aws_region
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_password        = var.db_password
}