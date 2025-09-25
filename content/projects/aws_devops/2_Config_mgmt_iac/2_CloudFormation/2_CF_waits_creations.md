---
title: "2: CloudFormation Wait Conditions & Creation Policies"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 12
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How are these similar but different?"
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
## What are wait conditions for?
- It's a CF resource, like anything else
	- `AWS::CloudFormation::WaitCondition`
- Makes the stack wait until key systems are operational
	- Wait for a __count__ of success signals
	- Could use a __timeout__
	- E.g. a NAT instance has to be configured before private instances try to hit the web
- For when we need to time things carefully, e.g.:
	- Ec2 instance needs stuff installed before continuing template build
- Hybrid environment: Signal to and from on-prem systems

## What's a creation policy?
- It's __an attribute__ associated with(in) resources
- Wait conditions are independent resources
- Recommended for ec2 and auto-scaling groups (ASG's)