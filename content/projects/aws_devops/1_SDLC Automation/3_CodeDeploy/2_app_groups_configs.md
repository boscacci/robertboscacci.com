---
title: "2: App, Groups, Configs"
toc: false
date: 2023-06-23T02:25:46-05:00
weight: 30
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

## What is a CodeDeploy "application"?
* A name identifier used reference your deployment settings.

## "Deployment Group"?
* Instance(s) where you want to target and deploy your code.
	* This could be even just one instance..!
	* Instance must have CodeDeploy agent installed in User Data

## "Deployment Configuration"?
* Set of rules and success/fail conditions used during deploy
* May vary depending on deployment medium (e.g. on-prem vs. lambda)
* Might specify e.g. # of instances that must remain avail during deploy
	* "Minimum healthy host" value (can be %)

## What's the order of ops for deploy?
1. Create the "application"
2. Specify deployment group
3. Specify deploy config
	* With "Min healthy hosts"
4. Upload our "revision" (the pkg to deploy)
5. Deploy
6. Check results
7. Redeploy as needed

## What are the Default Deployment Options?
* One at a time
* All at once
* Half at once

[More details on deploy configs can be found here](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html).