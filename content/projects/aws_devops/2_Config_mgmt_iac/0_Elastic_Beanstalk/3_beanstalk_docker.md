---
title: "3: Beanstalk Docker Deploys"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 04
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Whale plus beanstalk"
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

## Docker is one of the options in EB! 
(Next to e.g. Python)
<br/><br/>

# Single-container Deploys
- Dockerfile -> (build) -> image
- One instance, one container
- Beanstalk can do this for us
- Not ideal for multi-tier envs
	- e.g. web layer, app layer, db layer

# Multi-Container Deploys
- Several containers can run on same instances
- Separate containers for db, webapp, api
- `Docker run` file is mandatory for multi-container

## How to ensure scalability running docker on EB?
- Deploy 1 container per process with multi-container