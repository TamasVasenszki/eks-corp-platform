terraform {
  backend "s3" {
    key = "terraform.tfstate"
    bucket = "tomi-eks-corp-terraform-state-111"
    region = "eu-central-1"
    profile = "default"
    use_lockfile = true
    encrypt = true
  }
}