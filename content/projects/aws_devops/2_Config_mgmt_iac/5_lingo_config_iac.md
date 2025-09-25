---
title: "5: Conversations around Configs / iac"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 60
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Talk the jargon"
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
## How can we combine CloudFormation and Beanstalk?
- CF has a beanstalk resource type.
- Slam beanstalk into your CF templates

## How do we prevent RDS data loss when beanstalk deleted?
- Decouple RDS instances from beanstalk app; launch separately
- Mod inbound rules to allow access from beanstalk to RDS

## Can we use CDK instead of CF?
- Sure, it's more concise if you prefer Python / TypeScript etc
- It still resolves to CF under the hood

## Which deployment targets can we use with CodeDeploy?
- ec2
- __on-prem__
- lambda
- ecs

## How do we avoid reinventing the wheel in the CDK?
- Use __AWS Construct Library__

## Can you do serverless stuff in the CDK?
- Yes, or use SAM, it's a similar vibe

## In ASG: How to make sure old instances aren't terminated until new instances are up and running?
- Set `AutoScalingReplacingUpdate: WillReplace = true`