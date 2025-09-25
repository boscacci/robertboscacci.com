---
title: "5: Sec Info & Event Mgmt"
toc: false
weight: 50
draft: false
lastmod: 2023-07-11T02:25:46-05:00
related: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
  pass the aws devops professional certification by sharing his notes here."
summary: "Which services? How to use?"
Tags:
  - Robert Boscacci
  - DevOps
  - DevSecOps
  - NYC
  - New York City
  - Data Engineering
  - MLOps
  - AWS
---

## Automatable Security Services?
- GuardDuty
- Macie
- Inspector
- Security Hub
- Trusted Advisor
- Config

## GuardDuty
- Threat detection for accounts / workloads
- Findings can be sent to s3 __with Lambda__

## Macie
- S3 stuff
- Discover and protect sensitive data

## Inspector
- Sec / compliance __of apps__
- Also __Ec2 instances__
- Findings can be __piped to SNS__

## Security Hub
- What's a "hub"? Consolidates other services.
- Receives from the above ^ 3 services
- Security best practice checks
- Can delegate to systems manager for automated remediation

## Pro Tip
- Aggregate security findings into a single S3 bucket