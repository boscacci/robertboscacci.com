---
title: "8: Loose ends on incident response"
toc: false
weight: 80
draft: false
lastmod: 2023-07-11T02:25:46-05:00
related: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
  pass the aws devops professional certification by sharing his notes here."
summary: "Etcetera"
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

## Destinations for S3 bucket events?
- SNS
- SQS
- Lambda
- EventBridge

## What else about S3 is automated?
- Lifecycle expiration
- Lifecycle transition
- Intelligent tiering, archiving
- Object tagging

## Which services are event-driven?
- Lambda
- Cloudwatch
- EventBridge
- Kinesis

## Which ones also contribute to event-driven?
- CloudTrail: Findings can be actionable, trigger lambdas
- Config: Compliance issues, remediation actions
- S3: Use as repo, trigger pipeline actions on PUT

## What's, like, general security automation workflow?
1. Monitor
  - CloudWatch
  - CloudTrail
  - GuardDuty
  - Macie
2. Detect
  - SecurityHub
  - GuardDuty
3. Remediate
  - Lambda
  - Systems manager

## Sec / Compliance Monitoring:
- Lambda -> Trusted Advisor: Automate **security checks**
- Config -> Lambda: Download data from AWS config

## How to notify when access key in public repo?
- EventBridge event: `AWS_RISK_CREDENTIALS_EXPOSED`
- Step function: Delete keys