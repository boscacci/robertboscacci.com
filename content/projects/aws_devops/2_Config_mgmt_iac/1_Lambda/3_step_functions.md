---
title: "3: Deploying Step Functions"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 30
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Multi-step lambda workflows"
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

## What are step functions?
- A state machine implementation
- Coordinates AWS services into serverless workflows
- Multiple stages/steps; tasks, choices, timeouts
- Can be run parallel or serial

## Where to use step funcs?
- Longer than 15m runs
- When functions get bloaty and awkward
- Human approval / business processes
- Parallel execution of lambdas
	- e.g. both separate things need to work