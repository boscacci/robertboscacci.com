---
title: "0: CodePipeline Overview"
toc: false
date: 2023-06-26T02:25:46-05:00
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
* CD (continuous delivery) service to:
	* model
	* visualize
	* __automate__ 

...steps to ship code.

* Typical flow:
	* __Source__ (GitHub, codeCommit)
	* __Build__ (optional; compile, etc.)
	* __Staging__: Deploy, test, jenkins
	* __Production__: Deploy to public servers

* We can add in manual approvals
* Quickly model/configure stages
* __Build, test, deploy__ all in one

## Setup / Config:
* AWS CLI must be installed to compute
* IAM user setup
	* Must have some IAM policy / role
* Need codePipeline agent installed and running

## Can SNS get involved?
* Yes. Approval actions, triggers

## Lambda with CodePipeline?
* Yes.

## Eventbridge?
* Yes, can also be used with Pipeline

## Can GitHub or Jenkins be in a pipeline?
* Yes, sometimes you need an adapter