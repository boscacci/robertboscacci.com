---
title: "4: Beanstalk with RDS"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 05
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "SQL-like Database + Bean"
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

## Why not use packaged RDS in EB env?
- Fine for test and dev envs, perhaps
- They're tightly coupled:
	- When EB env is deleted, RDS DB will also be deleted

## Why create RDS DB separate from EB?
- RDS DB will not be deleted when EB env is trashed
- Decoupling is ideal for prod environments
- Seamless blue/green or canary deployments
	- Connect multiple envs to a DB