---
title: "2: EventBridge and SNS"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 20
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How do we chain them together?"
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

## How to do SNS + eventBridge for auto-scaling?
1. Create topic
2. Sub to the topic
3. Publish a test message
4. Create EventBridge event: Instance launch/terminate
5. Select SNS topic as target for event
6. Scale an auto-scaling group in or out

## Can we have multiple targets for same event?
- YES

## Are eventBridge events automatically linked to SNS topics?
- NO
- You have to link them manually
- This is a pub/sub model