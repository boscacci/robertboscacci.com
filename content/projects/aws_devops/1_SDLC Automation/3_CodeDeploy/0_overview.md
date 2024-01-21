---
title: "0: Overview"
toc: false
date: 2023-06-22T02:25:46-05:00
lastmod: 2023-06-21T02:25:46-05:00
weight: 10
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
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

## What is it?
* Automates application deployments to various servers:
	* Ec2 instances
	* On-prem instances
	* Lambda functions
	* ECS services

## What can you deploy?
* Code:
	* Java, C#, Lambda Funcs
	* Web and config files
	* Execs, pkgs, scripts
* Also multimedia files

## Where do deployables come from?
* GitHub / BitBucket
* S3
* CodeCommit via S3

## Where can we deploy to?
* Ec2 Placement Group
* Single ec2 instance
* Auto-scaling group
* Potentially cross-region

## How to get set up?
* Have IAM __user__ with CodeDeploy access (so you can use the service)
* Create IAM __instance profile__ (so ec2 can fetch artifacts from S3)
* Create IAM __service role(s)__ (so CodeDeploy can work with other AWS services like KMS)
	* Separate roles for lambda, ecs, ec2