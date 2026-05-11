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

module "s3" {
  source            = "./modules/s3"
  project_name      = var.project_name
  app_pod_role_name = module.eks.app_pod_role_name
}

module "lambda" {
  source         = "./modules/lambda"
  project_name   = var.project_name
  s3_bucket_name = module.s3.bucket_name
  s3_bucket_arn  = module.s3.bucket_arn
  health_url     = "http://k8s-default-ekscorpa-a3936bfaef-1754817892.eu-central-1.elb.amazonaws.com/health"
}