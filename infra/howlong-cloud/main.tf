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

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Use dev or production."
  }
}

locals {
  name     = "howlong-cloud-${var.environment}"
  zone     = "us-west-2a"
  archive  = "arn:aws:s3:::robertboscacci-howlong-archive-${var.environment}-062008221187"
  registry = "arn:aws:ecr:us-west-2:062008221187:repository"
  tags     = { Application = "howlong-cloud", Environment = var.environment, ManagedBy = "opentofu" }
}

resource "aws_vpc" "host" {
  cidr_block           = "10.94.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = local.name })
}

resource "aws_internet_gateway" "host" {
  vpc_id = aws_vpc.host.id
  tags   = local.tags
}

resource "aws_subnet" "host" {
  vpc_id            = aws_vpc.host.id
  availability_zone = local.zone
  cidr_block        = "10.94.0.0/26"
  tags              = local.tags
}

resource "aws_route_table" "host" {
  vpc_id = aws_vpc.host.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.host.id
  }
  tags = local.tags
}

resource "aws_route_table_association" "host" {
  subnet_id      = aws_subnet.host.id
  route_table_id = aws_route_table.host.id
}

resource "aws_security_group" "host" {
  name        = local.name
  description = "Outbound-only connector for SSM and Tailscale"
  vpc_id      = aws_vpc.host.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_iam_role" "host" {
  name = local.name
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }
  ] })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "runtime" {
  role = aws_iam_role.host.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = "ecr:GetAuthorizationToken", Resource = "*" },
    { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"],
    Resource = ["${local.registry}/robertboscacci-howlong", "${local.registry}/robertboscacci-trips-private"] },
    { Effect = "Allow", Action = "s3:GetObject", Resource = ["${local.archive}/resets/*", "${local.archive}/migration/*"] },
    { Effect = "Allow", Action = "s3:PutObject", Resource = "${local.archive}/resets/*",
    Condition = { StringEquals = { "s3:if-none-match" = "*" } } },
    { Effect = "Allow", Action = "cloudwatch:PutMetricData", Resource = "*",
    Condition = { StringEquals = { "cloudwatch:namespace" = ["HowLong/Archive/${var.environment}", "HowLong/Cloud/${var.environment}"] } } },
  ] })
}

resource "aws_iam_role_policy" "certificate" {
  count = var.environment == "production" ? 1 : 0
  role  = aws_iam_role.host.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = "route53:GetChange", Resource = "arn:aws:route53:::change/*" },
    { Effect = "Allow", Action = ["route53:GetHostedZone", "route53:ListResourceRecordSets"], Resource = "arn:aws:route53:::hostedzone/Z1BDNRWTPWQNUU" },
    { Effect = "Allow", Action = "route53:ChangeResourceRecordSets", Resource = "arn:aws:route53:::hostedzone/Z1BDNRWTPWQNUU",
      Condition = { "ForAllValues:StringEquals" = {
        "route53:ChangeResourceRecordSetsNormalizedRecordNames" = ["_acme-challenge.howlong.robertboscacci.com"],
        "route53:ChangeResourceRecordSetsRecordTypes"           = ["TXT"],
        "route53:ChangeResourceRecordSetsActions"               = ["CREATE", "UPSERT", "DELETE"]
    } } },
  ] })
}

resource "aws_iam_instance_profile" "host" {
  name = local.name
  role = aws_iam_role.host.name
  tags = local.tags
}

resource "aws_ebs_volume" "counter" {
  availability_zone = local.zone
  encrypted         = true
  size              = 1
  type              = "gp3"
  tags              = merge(local.tags, { Name = "${local.name}-state" })
  lifecycle { prevent_destroy = true }
}

resource "aws_instance" "host" {
  # Amazon Linux 2023 x86_64 standard AMI, resolved from the AWS public parameter.
  ami                         = "ami-001ef1bfba93a59ab"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.host.id
  vpc_security_group_ids      = [aws_security_group.host.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.host.name
  user_data                   = templatefile("${path.module}/bootstrap.sh", { volume_id = aws_ebs_volume.counter.id })
  credit_specification { cpu_credits = "standard" }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }
  tags       = merge(local.tags, { Name = local.name })
  depends_on = [aws_route_table_association.host, aws_iam_role_policy_attachment.ssm]
}

resource "aws_volume_attachment" "counter" {
  device_name = "/dev/sdf"
  instance_id = aws_instance.host.id
  volume_id   = aws_ebs_volume.counter.id
}

resource "aws_ecr_repository" "release" {
  count                = var.environment == "dev" ? 1 : 0
  name                 = "robertboscacci-howlong"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}

output "instance_id" { value = aws_instance.host.id }
