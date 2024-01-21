---
title: "1: Beanstalk Deployment Strats"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 02
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How to deploy"
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

# What Environment Types Exist?
* Single instance
	- Load balancer
	- Has an elastic IP
	- Still an auto-scaling group, just has one server
* High-availability
	- Load balancer
	- ASG
	- Group of instances

# Deployment types?

## All at once
- "In-place" deployment
- Fast swap
- No DNS changes
- Potentially catastrophic if problems

## Rolling
- Guarantee always 1 instance up at a time
- Instances detach / re-attach to load balancer (ELB)
- If it fails, it can get complicated

## Rolling w/ addl batches:
- Introduce new instances before decommissioning olds
- Prevents downtime
- Requires some more overhead, time
- If failure: Original ASG is still chillin

## Immutable
1. Completely new instances (prevent downtime)
2. Register new ones on ELB, do health checks
3. Kill old instances

## Blue/Green
1. Create entirely new environment (incl. ELB)
2. Swap route53 URLs; use DNS to redirect traffic.
- Requires more resources
- No downtime
- Test resources in isolation
- DNS changes could be weird

## Canary
- Much like blue/green—but split traffic bit by bit (via DNS)