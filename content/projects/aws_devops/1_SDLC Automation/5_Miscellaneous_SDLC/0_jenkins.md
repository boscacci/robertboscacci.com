---
title: "0: Jenkins w/ AWS Dev Tools"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 10
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Jenkins bby"
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

## What's Jenkins?
* OSS CI/CD tool. It's robust, common
* All jenkins configs need a `jenkinsfile`
* There are jenkins plugins for AWS. Jenkins can replace:
	- CodeBuild
	- CodeDeploy
	- CodePipeline
* Deployed in a manager/worker paradigm
	- Workers can be on separate instances (scalable)
	- One could have multiple managers in several AZ's

## Jenkins Config Example:
* Elastic IP —> EC2 jenkins server —> Auto-scaling worker group