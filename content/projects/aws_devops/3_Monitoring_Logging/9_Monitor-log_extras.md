---
title: "9: Monitoring / Logging: Supporting Services"
date: 2023-07-10T02:25:46-05:00
lastmod: 2023-07-10T02:25:46-05:00
weight: 90
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "👽😵"
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

# 1. AWS Compute Optimizer

## What is it?
- Uses ML to examine workloads
- Recommends optimizations
- Over/under provisioned?

## Services compute optimizer analyzes:
- Ec2
- EBS volumes
- ECS services on fargate
- Lambdas

# 2. AWS License Manager

## What is it?
- Define rules for licensed software
- Attach licensing rules on launch
- Search inventory & track licenses
- Use alerts to manage licenses across accounts __and on-prem__

# 3. Amazon Managed Prometheus (AMP) / Grafana

## What's AMP?
- Prometheus-compatible service
- Event monitoring and alerting __on containerized apps__
- Infrastructure at scale
- HTTP pool model

## What's Grafana?
- Managed service
- Query, viz, alert on metrics, logs, traces
- CHARTS

## Workflow?
1. Create AMP workspace
2. Run prometheus server to export app metrics to AMP
3. Config a grafana server on a remote desktop to query AMP workspace

# 4. Amazon AppFlow
- Automate bi-directional data flows
- Go between SaaS apps and AWS services. E.g.:
	- SalesForce
	- SAP
	- Google Analytics
- Drop it into S3 / redshift with transforms / validations
- Auto-scaling
