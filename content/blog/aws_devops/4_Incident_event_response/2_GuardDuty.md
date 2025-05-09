---
title: "2: GuardDuty"
toc: false
weight: 20
draft: false
lastmod: 2023-07-05T02:25:46-05:00
related: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
  pass the aws devops professional certification by sharing his notes here."
summary: "What it do?"
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

## What's GuardDuty?
- Provides __continuous analysis__ on __logfiles__:
  - VPC Flow logs
  - CloudTrail
  - DNS logs
- Integrated threat intelligence, __machine learning__ to identify threats
- Review findings in console, or w/ event management

## Can it be an eventbridge trigger?
- You bet your bottom dollar

## Where can results go?
- S3 bby

## How's it different from Inspector?
- Guardduty = Overall account, logs
- Inspector = specific applications

## How's it different from Macie?
- Macie is more about s3 data security / privacy
- GuardDuty = whole account