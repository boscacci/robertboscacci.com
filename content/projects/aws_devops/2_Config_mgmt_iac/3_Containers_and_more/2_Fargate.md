---
title: "2: Fargate Overview"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 30
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Serverless docker stuff on AWS"
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

# What's Fargate?
- Deals with containers
- Serverless
- Fronted by an application load balancer
- Operated via ECS
- Like ec2 but you get a container rather than a server

# Why use it?
- Don't want to manage servers
- Great for on-prem to cloud migration
- Microservice architectures
- Batch processing / ML

# How's it different from beanstalk?
- Strictly focused on containers

# How do you use it?
- Build container image
- Specify CPU and memory req's
- Define networking / IAM policies
- Launch

# What's a fargate task?
- One or more docker containers deployed with certain settings
- Task definition .json document

# Etc.
- You can add cloudwatch logging
- You can have Fargate clusters in public or private subnets
- Public load balancers accept web traffic and routes it to container
	- Thru ENI
- Private load balancer would only accept traffic from within the cluster