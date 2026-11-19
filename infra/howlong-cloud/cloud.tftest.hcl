mock_provider "aws" {}

run "cloud_dev_has_private_ingress_and_durable_state" {
  command = plan

  variables {
    environment = "dev"
  }

  assert {
    condition     = length(aws_security_group.host.ingress) == 0 && aws_instance.host.metadata_options[0].http_tokens == "required"
    error_message = "The host must have no public ingress and require IMDSv2."
  }

  assert {
    condition     = aws_ebs_volume.counter.encrypted && aws_instance.host.root_block_device[0].encrypted
    error_message = "Counter data and the host root disk must be encrypted."
  }

  assert {
    condition     = length(aws_ecr_repository.release) == 1 && aws_ecr_repository.release[0].image_tag_mutability == "IMMUTABLE"
    error_message = "The release registry must use immutable tags."
  }

  assert {
    condition     = length(aws_iam_role_policy.web) == 0
    error_message = "A compute-only preview must not get DNS or credential access."
  }
}

run "cloud_web_only_admits_https_for_its_exact_hostname" {
  command = plan

  variables {
    environment = "dev"
    public_web  = true
  }

  assert {
    condition     = length(aws_security_group.host.ingress) == 1 && one(aws_security_group.host.ingress).from_port == 443 && one(aws_security_group.host.ingress).to_port == 443
    error_message = "Only HTTPS may enter the cloud host."
  }

  assert {
    condition     = aws_route53_record.web[0].name == "howlong-dev.robertboscacci.com"
    error_message = "Development must have its own DNS name."
  }
}

run "production_reuses_the_registry_without_granting_dev_dns_writes" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = length(aws_ecr_repository.release) == 0
    error_message = "Production must reuse the dev artifact registry."
  }
}
