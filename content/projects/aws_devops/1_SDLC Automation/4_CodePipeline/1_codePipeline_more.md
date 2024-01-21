---
title: "1: More on CodePipeline"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 20
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "CodePipeline rationale"
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

## What can we do with pipeline once it's created?
* View it and its log files
* Edit; add stages, toggle transitions
* Retry the pipeline
* Delete it

## Can CodeBuild be used for both build and test?
* Yes! The entire build/test process can be __automated__ in codepipeline.

## Why "disable transition" between stages?
* Good for debugging certain segments of the pipeline
* E.g. test the build without hitting deployment

## Why use jenkins?
* Well suited for DevOps / agile methodologies that use quick iteration cycles

## Do we always want to automate the whole way to prod?
* No
* Sometimes we set up manual approval actions (e.g. to deploy)

## Why have approval actions?
* Code review
* QA / testing
* Review new / updated text before publishing

## Where can we add approval action steps?
* Within existing stages, or:
* Between stages, in a new stage

## How can we limit who is able to approve stuff?
* There's a managed IAM policy called "AWSCodePipelineApproverAccess"

## Troubleshooting:
* Remember to re-enable transitions after disabling
* No need for "key pair" on ec2; it's managed by pipeline