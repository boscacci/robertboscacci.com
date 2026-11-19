terraform {
  required_version = ">= 1.10.0"
  backend "s3" {
    bucket       = "robertboscacci-com-state-062008221187"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["062008221187"]
}

provider "aws" {
  alias               = "monitoring"
  region              = "us-east-1"
  allowed_account_ids = ["062008221187"]
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Use dev or production."
  }
}

variable "notifications_enabled" {
  type    = bool
  default = true
}

locals {
  name      = "robertboscacci-howlong-archive-${var.environment}"
  namespace = "HowLong/Archive/${var.environment}"
  tags      = { Application = "howlong", Environment = var.environment, ManagedBy = "opentofu" }
}

resource "aws_s3_bucket" "archive" {
  bucket = "${local.name}-062008221187"
  tags   = local.tags
  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "archive" {
  bucket                  = aws_s3_bucket.archive.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_policy" "archive" {
  bucket = aws_s3_bucket.archive.id
  policy = jsonencode({
    Version = "2012-10-17", Statement = [
      { Sid      = "RequireTLS", Effect = "Deny", Principal = "*", Action = "s3:*",
        Resource = [aws_s3_bucket.archive.arn, "${aws_s3_bucket.archive.arn}/*"],
      Condition = { Bool = { "aws:SecureTransport" = "false" } } },
      { Sid      = "RequireConditionalCreate", Effect = "Deny", Principal = "*", Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.archive.arn}/resets/*",
      Condition = { Null = { "s3:if-none-match" = "true" } } },
    ]
  })
}

resource "aws_iam_role" "writer" {
  name = local.name
  tags = local.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Effect = "Allow", Action = "sts:AssumeRole", Principal = { AWS = "arn:aws:iam::062008221187:user/rb-legion" }
    }]
  })
}

resource "aws_iam_role_policy" "writer" {
  role = aws_iam_role.writer.id
  policy = jsonencode({
    Version = "2012-10-17", Statement = [
      { Effect = "Allow", Action = "s3:GetObject", Resource = "${aws_s3_bucket.archive.arn}/resets/*" },
      { Effect = "Allow", Action = "s3:PutObject", Resource = "${aws_s3_bucket.archive.arn}/resets/*",
      Condition = { StringEquals = { "s3:if-none-match" = "*" } } },
      { Effect = "Allow", Action = "cloudwatch:PutMetricData", Resource = "*",
      Condition = { StringEquals = { "cloudwatch:namespace" = local.namespace } } },
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "archive" {
  provider            = aws.monitoring
  alarm_name          = "${local.name}-offline"
  alarm_description   = "How Long ${var.environment} archive stopped reporting success. Inspect the howlong-${var.environment}-archive user service journal on OptiPlex. The local reset records remain available for retry."
  actions_enabled     = var.notifications_enabled
  alarm_actions       = ["arn:aws:sns:us-east-1:062008221187:NotifyMe"]
  namespace           = local.namespace
  metric_name         = "Heartbeat"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  tags                = local.tags
}
