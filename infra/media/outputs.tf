output "media_url" {
  description = "Public media base URL."
  value       = "https://${var.domain_name}"
}

output "s3_bucket" {
  description = "Versioned S3 bucket for source media files."
  value       = aws_s3_bucket.media.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for media invalidations."
  value       = aws_cloudfront_distribution.media.id
}

output "site_media_env" {
  description = "Values for config/site-media.env."
  value = {
    SITE_MEDIA_BUCKET   = aws_s3_bucket.media.id
    SITE_MEDIA_BASE_URL = "https://${var.domain_name}"
    SITE_MEDIA_PREFIX   = "photos"
  }
}
