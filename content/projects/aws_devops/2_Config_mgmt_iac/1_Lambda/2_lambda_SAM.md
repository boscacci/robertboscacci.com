---
title: "2: Lambda SAM Framework"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 20
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What's that?"
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

## What is SAM?
- Sort of a bridge between Lambda and CF
- It's an open-source framework for serverless
- It's a CloudFormation extension for serverless
- It has its own CLI to provide a lambda-like env for local

## What format is SAM template?
- YAML not JSON
- (Same as CloudFormation)

## Why's it nice?
- Slap our templates into source control!
- Nice to be able to deploy to another region easily

## Can we include Lambda code in CF templates?
- YES
- Lambda -> SAM -> CF -> CF Template -> CF Stack

## How can we include SAM code in CF templates?
- Using the __transform function__ (?)

## What's in a SAM template?
- Resources
- Transform function
- Etc.