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
  description = "Public media hostname."
  type        = string
  default     = "media.robertboscacci.com"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for versioned site media."
  type        = string
  default     = "robertboscacci-com-media"
}

variable "cloudfront_cache_policy_id" {
  description = "Managed CloudFront cache policy. Defaults to Managed-CachingOptimized."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class for the media distribution."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common AWS tags."
  type        = map(string)
  default = {
    Application = "robertboscacci.com"
    Environment = "shared"
    ManagedBy   = "opentofu"
  }
}
