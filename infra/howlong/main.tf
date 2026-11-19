terraform {
  required_version = ">= 1.10.0"
  backend "s3" {
    bucket       = "robertboscacci-com-state-062008221187"
    key          = "howlong/opentofu.tfstate"
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

resource "aws_iam_role" "certificates" {
  name = "robertboscacci-howlong-certificates"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Effect = "Allow", Action = "sts:AssumeRole", Principal = { AWS = "arn:aws:iam::062008221187:user/rb-legion" }
    }]
  })
}

resource "aws_iam_role_policy" "dns_validation" {
  role = aws_iam_role.certificates.id
  policy = jsonencode({
    Version = "2012-10-17", Statement = [
      { Effect = "Allow", Action = ["route53:GetChange"], Resource = "arn:aws:route53:::change/*" },
      { Effect = "Allow", Action = ["route53:GetHostedZone", "route53:ListResourceRecordSets"], Resource = "arn:aws:route53:::hostedzone/Z1BDNRWTPWQNUU" },
      {
        Effect = "Allow", Action = "route53:ChangeResourceRecordSets", Resource = "arn:aws:route53:::hostedzone/Z1BDNRWTPWQNUU",
        Condition = { "ForAllValues:StringEquals" = {
          "route53:ChangeResourceRecordSetsNormalizedRecordNames" = ["_acme-challenge.howlong.robertboscacci.com"],
          "route53:ChangeResourceRecordSetsRecordTypes"           = ["TXT"],
          "route53:ChangeResourceRecordSetsActions"               = ["CREATE", "UPSERT", "DELETE"]
        } }
      }
    ]
  })
}
