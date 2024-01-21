---
title: "0: Lambda Overview"
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

## What's Lambda?
- A compute service: Run code without provisioning servers
- Absolutely no touching server config
- Only charged when code is running
- It's __stateless__ and __event-driven__
- It can do anything that we can program.

## How's it work?
1. Receives some event trigger, perhaps from:
	- S3
	- DynamoDB
	- API Gateway
	- SES
	- Eventbridge
2. Run some code
3. Log the run

## Lambda Requirements?
- Function code
- Memory size spec
- Execution timeout (15m max)
- IAM (execution) role
- Event source mapping

## Lambda funcs can be chained together

## What if you are dealing with longer time periods?
- Consider "step functions"
- Run multiple lambdas in parallel, potentially