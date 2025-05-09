---
title: "1: SDLC Automation Scenarios"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 20
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "Automation Scenarios"
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

## How to approach scenario questions:
- Maybe just mark them to figure out later
- Try to visualize
- Perhaps sketch on pad

## Which tools to manage access to CodeCommit repos?
- IAM policies, groups

## How to grant devs full access to CodeCommit without create/delete?
- "AWS CodeCommit Power User" policy

## Where do we store CodeBuild artifacts?
- S3 bucket

## How do we prepare that storage location?
- Turn on versioning.
- Turn on encryption.

## How do we make codebuild run after a code commit?
- EventBridge event to monitor codeCommit

## How can we implement code reviews and QA tests in automation pipeline?
- Add manual approval steps in the CodePipeline
- Give specific IAM groups the policy to approve pipeline steps