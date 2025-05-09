---
title: "7: Troubleshoot Failed Deploys"
toc: false
weight: 70
draft: false
lastmod: 2023-07-11T02:25:46-05:00
related: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
  pass the aws devops professional certification by sharing his notes here."
summary: "Which services? How to use?"
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

## Where to start when a CodeDeploy deployment fails?
- Instance profile: Do we have one? 
- AppSpec file: Properly configured? Right place?
- CodeDeploy Agent: Does ec2 instance have it?

## What role does tagging play in deployment?
- Say which instance(s) are included in a deploy grp