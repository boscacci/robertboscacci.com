---
title: "1: Lambda Versions & Aliases"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 06
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What are they?"
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

## How do versions and aliases work?
- Aliases are pointers to diff versions.
- Each function has a unique ARN
- Versions are immutable
- Latest version gets `$Latest` tag

## Aliases get their own ARN!
- Dev and Prod aliases are good to have!

## What are aliases good for?
- Canary deployments: Send 10% of traffic to new version
- No downtime with rapid rollback
- Good for debugging applications

## Careful pointing multiple aliases to same version!