---
title: "0: EventBridge / CloudWatch"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 01
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "A peek at EventBridge (formerly CloudWatch Events)"
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
- A serverless event bus — create custom buses
- Formerly CloudWatch Events -> now EventBridge
- Additional functionality, backwards compatible with old events

## How's it work?
1. EventBridge receives events.
2. If an event is tied to a rule,
3. Then perform some kind of action...
4. ...on some target (e.g. codePipeline)

## Can I make cloudwatch alarms in Ec2?
- Yes
- E.g. if CPU is under 10% utilization for 10m, __stop instance__

## What triggers our auto-scaling policies?
- CloudWatch Alarms.
- Scale on CPU or __custom metrics__ like memory utilization
- E.g. if CPU utilization exceeds 80%, scale up

## What are some Ec2 metrics to evaluate for scaling?
- CPUUtilization
- DiskReadOps
- DiskWriteOps
- __NOT Memory usage__