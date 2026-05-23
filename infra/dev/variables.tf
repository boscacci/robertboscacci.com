variable "aws_region" {
  description = "Region for the S3 bucket and regional resources. CloudFront ACM is always created in us-east-1."
  type        = string
  default     = "us-west-2"
}

variable "zone_name" {
  description = "Public Route53 hosted zone name."
  type        = string
  default     = "robertboscacci.com."
}

variable "domain_name" {
  description = "Development preview hostname."
  type        = string
  default     = "dev.robertboscacci.com"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the development site artifact."
  type        = string
  default     = "robertboscacci-com-dev-site"
}

variable "cloudfront_cache_policy_id" {
  description = "Managed CloudFront cache policy. Defaults to Managed-CachingOptimized."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class for the development distribution."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common AWS tags."
  type        = map(string)
  default = {
    Application = "robertboscacci.com"
    Environment = "development"
    ManagedBy   = "opentofu"
  }
}

variable "github_owner" {
  description = "GitHub repository owner allowed to deploy the development site."
  type        = string
  default     = "boscacci"
}

variable "github_repo" {
  description = "GitHub repository name allowed to deploy the development site."
  type        = string
  default     = "robertboscacci.com"
}

variable "github_actions_role_name" {
  description = "IAM role name assumed by GitHub Actions for development deploys."
  type        = string
  default     = "robertboscacci-com-dev-github-actions"
}
