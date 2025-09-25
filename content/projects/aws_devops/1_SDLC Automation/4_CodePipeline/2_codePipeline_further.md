---
title: "2: Even More on CodePipeline"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 30
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "CodePipeline w/ eventbridge, edge cases"
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

## Where can eventBridge stuff happen in the pipeline?
### Source
- e.g. successful merge:
- Trigger __lambda__ here!
### Build
- Success/fail
- Trigger SNS
### Deploy
- Deployed, tested
- Trigger SNS
### Monitor
- Health checks
- Trigger SNS

## EventBridge is a superset of CloudWatch Events.
* We can set up conditional actions based on success/fails

## What are the essential automation glue tools?
* EventBridge (the new CloudWatch)
* Lambda
* SNS