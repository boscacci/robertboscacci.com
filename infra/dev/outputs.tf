output "dev_url" {
  description = "Development preview URL."
  value       = "https://${var.domain_name}/"
}

output "s3_bucket" {
  description = "S3 bucket for the development site artifact."
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for GitHub Actions invalidations."
  value       = aws_cloudfront_distribution.site.id
}

output "github_actions_variables" {
  description = "Repository or environment variables needed by .github/workflows/dev-preview.yml."
  value = {
    AWS_REGION                         = var.aws_region
    AWS_ROLE_TO_ASSUME                 = aws_iam_role.github_actions.arn
    DEV_S3_BUCKET                      = aws_s3_bucket.site.id
    DEV_CLOUDFRONT_DISTRIBUTION_ID     = aws_cloudfront_distribution.site.id
    DEV_CLOUDFRONT_DISTRIBUTION_DOMAIN = aws_cloudfront_distribution.site.domain_name
  }
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC development deploys."
  value       = aws_iam_role.github_actions.arn
}
