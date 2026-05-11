resource "aws_s3_bucket" "company" {
  bucket = "${var.project_name}-company"

  tags = { Name = "${var.project_name}-company" }
}

# Blockin the public access
resource "aws_s3_bucket_public_access_block" "company" {
  bucket = aws_s3_bucket.company.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "company" {
  bucket = aws_s3_bucket.company.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM policy - uploads folder
resource "aws_iam_policy" "s3_uploads" {
  name = "${var.project_name}-s3-uploads-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.company.arn}/documents/*"
      }
    ]
  })
}

# IAM policy - reports folder (read only)
resource "aws_iam_policy" "s3_reports" {
  name = "${var.project_name}-s3-reports-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.company.arn,
          "${aws_s3_bucket.company.arn}/reports/*"
        ]
      }
    ]
  })
}

# Add the S3 policy to the App pod role
resource "aws_iam_role_policy_attachment" "app_s3_uploads" {
  role       = var.app_pod_role_name
  policy_arn = aws_iam_policy.s3_uploads.arn
}