# S3 bucket for static files
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.project_name}-static-site"
  tags   = { Name = "${var.project_name}-static-site" }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket                  = aws_s3_bucket.static_site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "${var.project_name}-cloudfront" }
}

# S3 bucket policy - only CloudFront access
resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.static_site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })
}

# Upload files to S3
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "index.html"
  source       = "${path.root}/../../static-site/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/../../static-site/index.html")
}

resource "aws_s3_object" "style" {
  bucket       = aws_s3_bucket.static_site.id
  key          = "style.css"
  source       = "${path.root}/../../static-site/style.css"
  content_type = "text/css"
  etag         = filemd5("${path.root}/../../static-site/style.css")
}