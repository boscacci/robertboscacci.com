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
    condition     = length(aws_iam_role_policy.certificate) == 0
    error_message = "Development must not get certificate DNS write access."
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
