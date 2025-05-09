---
title: "3: Auditing"
date: 2023-07-11T02:25:46-05:00
lastmod: 2023-07-11T02:25:46-05:00
weight: 30
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What happens wen audit?"
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

## Which services do we think of?
- Config writes to s3
- You can review changes in console
- We can of course automate with SNS, lambda
- Systems manager automations for auto-heal

## What key services can analyze CloudTrail log files?
- Quicksight
- Athena
- CloudWatch

## How to set up auto-notify of config changes?
- AWS Config + SNS (or lambda)

## How to identify resources in acct that can be accessed externally?
- IAM Access analyzer

## What's amazon quicksight?
- Quick analysis, charting capabilities
- BI service