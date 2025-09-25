---
title: "3: CloudTrail"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 30
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Audit logs"
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

## What is it?
- Keeps an eye on various services and __logs interactions__
- Records user interactions, __API calls__
- Managed thru CLI, SDK, or web console
- Interacts with most AWS services:
	- VPC
	- EC2
	- RDS
	- EBS
	- IAM
	- Etc.

## What's it good for?
- Security analysis, compliance auditing
- Storing logs just in case: Audit in 6 months
- Operational troubleshooting
- __Take action__ when important events detected
- Review recent events in the console
- Analyze logfiles w/ Athena

## Can logfiles from multiple accounts be consolidated?
- Yes, they drop into s3 buckets
- Multiple accounts can have access to s3 bucket
- Just create a bucket policy with cross-account access

## How can we guarantee the integrity of logfiles in s3?
- Enable __log file validation__ on CloudTrail
- Lets us know if a logfile has been modified/deleted
- This is set up _in CloudTrail_

## What to do for cheaper log storage?
- Ship from s3 to glacier

## Diff from CloudWatch?
- CloudWatch has logging, but logging of __API calls__ is all CloudTrail

## Are logFiles encrypted?
- Yes, using s3 managed encryption keys (SSE-S3)
- You can go manual encryption with __SSE-KMS__
	- Create a policy, attach to key, to give access