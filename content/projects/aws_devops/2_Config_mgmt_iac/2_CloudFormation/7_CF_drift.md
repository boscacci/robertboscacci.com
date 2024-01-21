---
title: "7: CF Drift Detection & Remediation"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 17
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Keep it modular"
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
# (Not v important for the exam)

## What's drift?
- Modifying stuff in the stack, but not from the template
- Now CF template doesn't reflect topology of the stack
- This is bad for disaster recovery (DR)
- E.g. adding an EIP to ec2 instance, but not in template
	- Deletion will fail

## How to detect + avoid drift?
- AWS Config:
	- Run config rule: `cloudformation-stack-drift-detection-check`
	- Slap some SNS on it
- Limit who can change stack resources