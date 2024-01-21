---
title: "1: ECS Overview"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 20
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Docker containers on AWS"
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

# First, what is ECR?
- Docker hub but on AWS and private
- Fully-managed container image registry
- Works seamlessly with ECS, EKS, fargate
- Compress, encrypt, control access

# Then what's ECS?
- Deploy docker images from ECR
- "Run anywhere"
- Use docker imgs in task definitions to launch containers as part of tasks in clusters

## What are task definitions?
- __Task definitions__ use docker to launch containers on the container instances in clusters

## Workflow:
1. Create container image
2. Push to ECR / Docker Hub
3. Task definition: Parameters for the app
4. Container image is pulled from registry