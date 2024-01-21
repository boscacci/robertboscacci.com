---
title: "0: OpsWorks"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 10
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Chef, puppet on AWS"
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

# What is OpsWorks?
- Configuration management tool
- Managed instances of __Chef and Puppet__
- Use code to automate instance config

# OpsWorks Anatomy
- aws -> stack -> layer -> instance -> app
- Every stack has at least 1 layer
- Stacks have layers such as:
	- Load balancer layer
	- App server layer
	- RDS layer
- Layers modularize our stacks
	- Use chef recipes to customize the stack
- Instances sit in layers
	- Instances can be 24/7, load-based, time-based

# In what order are stacks created?
1. Create stack
2. Add layers
3. Add instances
4. Add apps
5. Deploy apps (finished w/ chef recipes)

# Deployment
- On each event, different scripts can run
- 5 lifecycle events in each layer:
	1. Setup
	2. Configure
	3. Deploy
	4. Undeploy
	5. Shutdown

## Deployment Types

### Manual
- All-at-once
- Fast
- Lowered capacity

### Rolling
- Prevent downtime
- Don't double resources
- Failures reduce capacity

### Blue/Green
- DNS switch from one load balancer to another
- Totally clean new environment
- Doubling our resources, intensive


# Exam Tips
- OpsWorks is less granular than CF
- OpsWorks works with chef recipes
- Elastic beanstalk is better for super short app lifecycle
- OpsWorks focuses on core resources; CF is everything