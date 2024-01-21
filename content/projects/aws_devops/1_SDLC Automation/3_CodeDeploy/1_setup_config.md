---
title: "1: Setup & Config"
toc: false
weight: 20
date: 2023-06-22T02:25:46-05:00
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

## What are revisions?
* The package type things we deploy in CodeDeploy

## What's the Deployment Configuration?
* Specifies how to deploy, and _at what rate_
	* Disaster recovery?
* Deployment method determines rate of deployment

## What's a Deployment Group?
* It's where we deploy to.
* Could be a single instance or many
	* Could be one of many OS'es
* Could also be Lambda or ECS

## How do we bring in some automation?
* EventBridge to monitor deployments
	* Create an SNS topic to subscribe to
	* Make a Lambda to do stuff with e.g. Slack