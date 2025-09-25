---
title: "1: CodeBuild Projects"
toc: false
lastmod: 2023-06-10T02:25:46-05:00
weight: 20
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

## What are CodeBuild Projects?

* CodeBuild requires a __build project:__
	* The build project creates a build env
	* Can be created via CLI or console
	* Project contains info about how to run a build:
		* Where src code?
		* Which env to use?
		* Which commands to run?
		* Where to deposit output artifact? (on S3)

## What is a "buildspec" file?
* It's the buildspec.yml file with build commands + settings
* Must be in root of code source directory
* Usually zipped with the src code, but can be uploaded with build project
* buildspec.yml has phases:
	* Install (e.g. Apache Maven)
	* Pre-build (e.g. connect to ECR)
	* Build (e.g. compile the .jar)
	* Post-build (e.g. confirmation message)
* Each phase has commands
	* Regular arbitrary shell commands to run
	* "finally" commands which run regardless of ^ outcome

## What are potential code sources for CodeBuild?
* CodeCommit
* S3 bucket (w/ versioning enabled)
* GitHub (enterprise) / Bitbucket

## Must you (manually) run CodeBuild after CodeCommit merges?
* You could set up a cloudWatch event to watch your repo
	* On successful merge, run builds automatically

## How would you notify personnel re: new build logs?
* CodeBuild -> CloudWatch (AKA eventBridge) event to listen for logs
	* CloudWatch (EventBridge) Event -> SNS (text, email)
	* CloudWatch (EventBridge) Event -> Lambda f'n -> Slack / Discord

## Where do Build Artifacts End Up?
* S3 bucket

## Is a service role needed to work with other AWS services?
* Yes; e.g. if you need to tie into codebuild, Lambda, or CF

# What do you need if working with a VPC?
* VPC ID
* Subnet IDs
* Security groups
* These might apply if working with ec2 instances

## Etcetera
* We can tie in SNS for notifications
* We can use CloudWatch for logging
* Buckets have to be in the same region as build