---
title: "8: DevOps Conversations"
toc: false
date: 2023-06-27T02:25:46-05:00
weight: 90
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Talk the talk"
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

# Q&A

### Regarding CodeBuild, could I include an AppSpec file as part of the source code?
- AppSpec is for CodeDeploy.
- BuildSpec file can be included with src.

### Between buildspec and appspec files, which has lifecycle hooks?
- AppSpec.

### ...and how are they used?
- Run scripts during diff stages of deploy

### With _CodeDeploy_, what deployment targets can we use?
- Ec2
- Lambda
- EC2
- On-prem servers

### For these targets, are the hooks the same in the AppSpec?
- No
- Specific types of hooks per deployment type
- Ec2 has many hooks
- ECS has some hooks
- Lambda has __few__ hooks

### Name a few tools: One for Source, build, deploy
- GitHub for src
- Jenkins for build/deploy