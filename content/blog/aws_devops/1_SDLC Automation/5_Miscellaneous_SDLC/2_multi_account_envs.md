---
title: "2: Multi-Account Envs"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 30
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Multi-account"
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

## Why deploy to multiple accounts?
- Apply appropriate security to each account
- Appropriate security for access to the env
- Appropriate security for access to database
- __Isolation is good__: Limit impact of errors

## What sort of accounts might we want?
- Dev
- Test
- Prod

## Who can use prod?
- Only: An admin, and the pipeline

## How to publish to another account?
- Cross-account role is instrumental here