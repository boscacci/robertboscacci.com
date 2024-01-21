---
title: "7: Supporting Services"
toc: false
date: 2023-06-27T02:25:46-05:00
weight: 80
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Loose ends for SDLC"
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

## AWS App Runner
* Fully managed container app service
* Build/run/deploy containerized apps/APIs — without learning containers
* Sort of like Fargate*
	* Except you specify how many concurrent requests each app container instance to field
	* Fargate leaves concurrency / scaling up to you
	* (Fargate is __easier to config__ but less customizable than K8s)

## AWS CloudShell
* Browser-based, pre-authenticated shell
* Launch from AWS console
* Run various shells:
	- Bash
	- Powershell
	- zshell
* Run CLI commands quickly without an instance.

## AWS CodeStar
* __Development__ service
* Use __project templates__ to make apps
* Works with ec2, lambda, beanstalk
* Connects codecommit, pipeline, deploy w/ templates
* It's like an overlay or dashboard over the SDLC tools

## How is Cloudshell pre-authenticated?
* You launch it from the console, where you're already logged in

## Fargate, K8s, app runner: Order of complexity?
1. K8s most complex
2. Fargate middle
3. App runner simplest