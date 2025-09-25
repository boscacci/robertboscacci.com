---
title: "5: EC2 Image Builder"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 60
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Automates ec2 Builds"
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

## What's Ec2 img builder?
- Create automated pipeline to:
	- Create custom images
	- Maintain them
	- Test them
- What kind of images can it make?
	- Ec2 AMIs
	- Docker images (!)

## How does it work?
- Take a base image
- Customize it
- Secure it
- Test it
- Distribute the final "golden" image

## What types of imgs can be customized?
- EC2 AMI and Docker!

## How to automate updates and system patching for imgs?
- Make a pipeline in EC2 img builder

## What's a "golden" AMI or docker image?
- One you standardize thru config, security patching, hardening
- It has to do with Image Builder