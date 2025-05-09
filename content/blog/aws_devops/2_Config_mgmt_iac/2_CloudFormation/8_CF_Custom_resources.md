---
title: "8: CF Custom Resources"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 18
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "They're always adding more"
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
## What are these?
- It's like throwing Lambdas into CloudFormation
- They can do basically anything, return anything

## What could I use custom resources for?
- Manage non-aws resources, e.g. third-party API
- Complex/custom logic, e.g. load data into an RDS instance
- Retrieve dynamic data, like variable AMIs
- Extend existing resources, e.g. logging, error-checking
- Manage AWS resources not yet supported in CF

## How does CF use these?
1. Retrieve package source from S3
2. Deploy lambda func
3. Run lambda, return data to CF
4. CF continues with rest of deploy

## What's needed to use lambdas in CF?
1. Custom resource (service token)
2. Lambda execution role (permission)
3. Lambda function
	- Can be inline or S3 zipfile