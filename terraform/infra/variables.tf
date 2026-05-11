variable "project_name" {
  type    = string
  default = "tomi-eks-corp-platform"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "image_tag" {
  description = "Docker image tag for the app image stored in ECR"
  type        = string
  default     = "v1"
}

variable "db_password" {
  type = string
  sensitive = true
}