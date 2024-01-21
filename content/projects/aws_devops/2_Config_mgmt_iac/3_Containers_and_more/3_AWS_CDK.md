---
title: "3: AWS Cloud Development Kit"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 40
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "CloudFormation but in hi-level langs"
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

# What's the CDK?
- Framework to define and provision cloud infra in code
- Wrapper on top of CloudFormation
- Use the __aws constructs library__

# Why use CDK?
- Much more concise than CloudFormation
- Write in Python / TypeScript / Java(Script) / Go / etc.
- Can fit in pipelines and automations like CF

# How does CDK work?
1. __App__
	- Root of construct tree (like a folder)
	- Consolidates all stacks in one app
2. __Stack__
	- Single unit holding constructs
	- Can be used for development
3. __Construct__
	- Building block containing one or more AWS resources
	- Reusable