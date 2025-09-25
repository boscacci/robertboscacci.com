---
title: "2: AWS Config"
date: 2023-07-11T02:25:46-05:00
lastmod: 2023-07-11T02:25:46-05:00
weight: 20
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "AWS Config"
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

## What is AWS Config?
- Assess, audit, evaluate resource configs
- Continuously monitor and record config data
- Create asset inventory
- Build rules to ensure compliance

## Can it be used over accounts/regions
- Yes

## Where does it record config logs?
- S3

# How to distinguish Config from CloudTrail?

## Similarities:
- Keyword "audit"
- Monitoring for AWS services
- Track / store history of changes
- Compliance and governance

## Differences:
- Config reports on __what has changed__
- Config focuses on AWS resources, not API calls