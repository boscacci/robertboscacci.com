---
title: "4: Revision and Deployment"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 50
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How do we get a revision deployed?"
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
## What's a "revision" again?
* Deployable content, probably in S3
* Must be .zip or .tar or .jar or somesuch

## What's the codedeploy command to bundle a revision?
* `aws codedeploy push`
* Combines creating an application revision and uploading the revision files to an Amazon S3 bucket

## How to e.g. do custom verification actions?
* Use, say, [`AfterAllowTraffic` hook](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html)

## How do you know when ready to deploy?
* Application is bundled
	- i.e. bundled a revision; something to deploy
* Deployment group exists
	- One instance? Auto-scaling? Lambda?
* Deployment configuration is ready
	- appspec.yml
	- (Actually optional)

## Is a deployment config mandatory?
* No! It's optional
* Useful tho to control rate of deploy