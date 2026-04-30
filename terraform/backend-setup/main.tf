resource "aws_s3_bucket" "terraform_state" {
  bucket = "tomi-eks-corp-terraform-state-111"
}

resource "aws_dynamodb_table" "terraform_lock" {
  name = "tomi-eks-corp-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}