---
title: "9: Deployment Strats & Test Scenarios"
toc: false
date: 2023-06-27T02:25:46-05:00
weight: 100
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Ways to skin a cat"
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
# Ways to Deploy

## S3
- CodeDeploy straight from code in a bucket to:
	- Lambda
	- Ec2
	- ECS

## ECS
- src in CodeCommit
	- Do code reviews
- Build in CodeBuild
	- Use buildspec file
	- Deposit artifacts to s3
	- Perhaps register img to ECR
	- Run unit/other tests
- CodeDeploy
	- Use appspec
	- Manual approval?
	- Deploy to ECS

## Beanstalk
- src in s3 perhaps
- CodeBuild
- CodeDeploy
- Beanstalk (another one of several "deployment providers")

## Lambda
- Src: CodeCommit
- Build: CodeBuild
- Deploy: CloudFormation
- to: Lambda

## CodePipeline Action Types
- INVOKE (as in, Lambda)
- Source
- Build
- Test
- Deploy
- Approve

### "Invoke" Use Cases?
- Create resources (e.g. servers) on demand
- Zero-downtime Beanstalk deployments using lambda to swap CNAME
- Deploy ECS docker instances
- Back up resources before deploying

## CloudFormation
- Src: CodeCommit
- Build
- Deploy
- CF stack (via template)
	- Can be validated with cfn-lint in buildspec

<br/>

# Misc Exam Knowledge

## How to swap cnames in a beanstalk deployment?
- Lambda

## What Deployment groups can we create in codeDeploy?
- EC2 (or on-prem)
- ECS
- Lambda