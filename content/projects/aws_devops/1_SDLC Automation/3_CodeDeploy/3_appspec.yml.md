---
title: "3: appspec.yml"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 40
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "The config file for codedeploy"
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
## How to run custom actions during deploy?
* Appspec file; lifecycle

## What's the appspec.yml?
* Manages each deployment as __a series of lifecycle event hooks__
	* YAML or JSON format
* hooks = run custom code at specific times during deploy

## What's defined in the appspec?
* Version # (0.0)
* OS (e.g. linux)
* Files
	* Copied to compute on deployment
	* Src: Location in the revision
	* Dest: Location on the compute
* Hooks, e.g.:
	* BeforeInstall
	* AfterInstall
	* ApplicationStart
	* ValidateService
	* AfterAllowTraffic
	* See more at https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html
* Deploying to different outlets (lambda, ecs) require different appspec