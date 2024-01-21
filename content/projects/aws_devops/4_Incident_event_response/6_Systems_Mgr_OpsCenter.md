---
title: "6: Systems Manager / OpsCenter"
toc: false
weight: 60
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

## What's OpsCenter?
- A central spot to manage operational **"work item"**
  - Issue / interruption that needs investigation / fix
  - Aka **"OpsItem"**
- (A capability of SystemsManager)
- Helpful to reduce mean TTR

Automatically Create OpsItems in OpsCenter.

## What's it integrate with?
- CloudWatch Alarms
- EventBridge Events

## The sort of stuff it listens for:

### From CloudWatch Alarms:
- DB r/w reaches some threshold
- CPU Utilization reaches some threshold
- Billing / charges reach some thresh
- Ec2 instance fails a status check
- EBS disk space running low

### From EventBridge:
- Security Hub: Alert issued
- DB: Throttling event
- ASG: Failure to launch instance
- Systems Mgr: Failure to run
- AWS Health: Alert for regular maintenance
- EC2: Instance state change