---
title: "9: CF StackSets"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 19
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Stack sets?"
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
# What are StackSets?
- C/R/U/D stacks across multiple accounts/regions in a single operation
- Has to be a stack deployed from admin account
- __Target__ account is where you create/update/delete 1+ stacks in the set

# Permission Models:

## Self-managed:
- Deploy stack sets to any account where you're allowed
- Create IAM roles that set up trust between accounts

## Service-managed:
- Deploy stack instances to accounts managed by AWS Orgs
- IAM roles and trust are created for you
- (This is nice, but more up-front work)

# Pipelines for StackSets
- In e.g. codeBuild, the buildspec file has changes against stack sets

# Exam Tips

## Where can you deploy StackSets?
- Across accounts and regions

## Which types of accounts are required for StackSets?
- An __admin__ acct and __target__ accounts

## What permission models are used with StackSets?
- Self-managed (IAM DIY)
- Service-managed (AWS Orgs integration)