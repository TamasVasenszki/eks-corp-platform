# Zipping Lambda code
data "archive_file" "health_check" {
  type        = "zip"
  source_dir  = "${path.root}/../../lambda/health-check"
  output_path = "${path.module}/health-check.zip"
}

# Dedicated IAM policy for Lambda
resource "aws_iam_policy" "lambda_health_check" {
  name = "${var.project_name}-lambda-health-check-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/documents/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/reports/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_health_check" {
  name = "${var.project_name}-lambda-health-check-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_health_check" {
  role       = aws_iam_role.lambda_health_check.name
  policy_arn = aws_iam_policy.lambda_health_check.arn
}

# Lambda function
resource "aws_lambda_function" "health_check" {
  filename         = data.archive_file.health_check.output_path
  function_name    = "${var.project_name}-health-check"
  role             = aws_iam_role.lambda_health_check.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.health_check.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
      HEALTH_URL     = var.health_url
    }
  }
}

# EventBridge rule - runs hourly
resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "${var.project_name}-health-check-schedule"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "health-check-lambda"
  arn       = aws_lambda_function.health_check.arn
}

resource "aws_lambda_permission" "health_check" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}