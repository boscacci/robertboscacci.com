---
title: "5: Kinesis + Lambda"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 50
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How do they interact?"
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

## Architecture
- Custom application triggers data stream
- Data stream feeds to lambda
- (Need executon role for lambda)
- Stream out from Lambda to CloudWatch

## Steps
1. Write records to streams
2. Lambda polls the stream. When new records detected...
3. Invoke lambda
4. Assume the execution role specified

## Lambda Function
- Needs execution role to read kinesis, write logs to CloudWatch

## Input File

## Are "Kinesis Data Streams" input or output?
- It often acts as both input and output