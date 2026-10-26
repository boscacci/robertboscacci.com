terraform {
  required_version = ">= 1.10.0"
  backend "s3" {
    bucket       = "robertboscacci-com-state-062008221187"
    key          = "trips/opentofu.tfstate"
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
  alias               = "use1"
  region              = "us-east-1"
  allowed_account_ids = ["062008221187"]
}
locals {
  environments = { dev = "trips-dev.robertboscacci.com", production = "trips.robertboscacci.com" }
  zone_id      = "Z1BDNRWTPWQNUU"
}
resource "aws_s3_bucket" "site" {
  for_each = local.environments
  bucket   = "robertboscacci-com-trips-${each.key}-062008221187"
  tags     = { Application = "family-trips", Environment = each.key, ManagedBy = "opentofu" }
}
resource "aws_s3_bucket_public_access_block" "site" {
  for_each                = local.environments
  bucket                  = aws_s3_bucket.site[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "site" {
  for_each = local.environments
  bucket   = aws_s3_bucket.site[each.key].id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  for_each = local.environments
  bucket   = aws_s3_bucket.site[each.key].id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}
resource "aws_acm_certificate" "site" {
  provider          = aws.use1
  for_each          = local.environments
  domain_name       = each.value
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}
resource "aws_route53_record" "validation" {
  for_each = local.environments
  zone_id  = local.zone_id
  name     = one(aws_acm_certificate.site[each.key].domain_validation_options).resource_record_name
  type     = "CNAME"
  ttl      = 60
  records  = [one(aws_acm_certificate.site[each.key].domain_validation_options).resource_record_value]
}
resource "aws_acm_certificate_validation" "site" {
  provider                = aws.use1
  for_each                = local.environments
  certificate_arn         = aws_acm_certificate.site[each.key].arn
  validation_record_fqdns = [aws_route53_record.validation[each.key].fqdn]
}
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "family-trips-s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_response_headers_policy" "site" {
  name = "family-trips-private-content"
  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow, noarchive"
      override = true
    }
    items {
      header   = "Cache-Control"
      value    = "no-store"
      override = true
    }
  }
  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "no-referrer"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = true
    }
  }
}
resource "aws_cloudfront_function" "routes" {
  name    = "family-trips-canonical-routes"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-JS
    function handler(event) {
      var r = event.request;
      // Only individual trip documents and robots are public. No index, listing,
      // health endpoint, release archive, or private renderer can be fetched.
      if (r.uri === '/robots.txt') return r;
      if (!/^\/[a-z0-9]+(?:-[a-z0-9]+)+\/(?:index\.html)?$/.test(r.uri)) {
        return { statusCode: 404, statusDescription: 'Not Found',
          headers: { 'cache-control': { value: 'no-store' }, 'x-robots-tag': { value: 'noindex, nofollow, noarchive' } }, body: 'Not found' };
      }
      if (r.uri.endsWith('/')) r.uri += 'index.html';
      return r;
    }
  JS
}
resource "aws_cloudfront_distribution" "site" {
  for_each        = local.environments
  enabled         = true
  is_ipv6_enabled = true
  aliases         = [each.value]
  comment         = "Family trips ${each.key}: encrypted public documents only"
  price_class     = "PriceClass_100"
  origin {
    domain_name              = aws_s3_bucket.site[each.key].bucket_regional_domain_name
    origin_id                = "trips"
    origin_path              = "/public"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }
  default_cache_behavior {
    target_origin_id           = "trips"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    compress                   = true
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.routes.arn
    }
  }
  custom_error_response {
    error_code            = 403
    response_code         = 404
    error_caching_min_ttl = 0
  }
  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site[each.key].certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
resource "aws_s3_bucket_policy" "site" {
  for_each = local.environments
  bucket   = aws_s3_bucket.site[each.key].id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Principal = { Service = "cloudfront.amazonaws.com" }, Action = "s3:GetObject",
    Resource  = "${aws_s3_bucket.site[each.key].arn}/public/*",
    Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.site[each.key].arn } }
  }] })
}
resource "aws_route53_record" "site" {
  for_each = { for p in setproduct(keys(local.environments), ["A", "AAAA"]) : "${p[0]}-${p[1]}" => { environment = p[0], type = p[1] } }
  zone_id  = local.zone_id
  name     = local.environments[each.value.environment]
  type     = each.value.type
  alias {
    name                   = aws_cloudfront_distribution.site[each.value.environment].domain_name
    zone_id                = aws_cloudfront_distribution.site[each.value.environment].hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_iam_role" "certificates" {
  name = "robertboscacci-trips-certificates"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "sts:AssumeRole",
  Principal = { AWS = "arn:aws:iam::062008221187:user/rb-legion" } }] })
}
resource "aws_iam_role_policy" "certificates" {
  role = aws_iam_role.certificates.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["route53:ListHostedZonesByName", "route53:GetChange"], Resource = "*" },
    { Effect = "Allow", Action = ["route53:GetHostedZone", "route53:ListResourceRecordSets"], Resource = "arn:aws:route53:::hostedzone/${local.zone_id}" },
    { Effect = "Allow", Action = "route53:ChangeResourceRecordSets", Resource = "arn:aws:route53:::hostedzone/${local.zone_id}", Condition = {
      "ForAllValues:StringEquals" = { "route53:ChangeResourceRecordSetsNormalizedRecordNames" = ["_acme-challenge.trips.robertboscacci.com", "_acme-challenge.trips-dev.robertboscacci.com"],
      "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"], "route53:ChangeResourceRecordSetsActions" = ["UPSERT", "DELETE"] }
    } }
  ] })
}
output "environments" {
  value = { for env, host in local.environments : env => { host = host, bucket = aws_s3_bucket.site[env].id,
  distribution = aws_cloudfront_distribution.site[env].id, edge_domain = aws_cloudfront_distribution.site[env].domain_name } }
}
