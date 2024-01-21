---
title: "7: AWS OpenSearch"
date: 2023-07-10T02:25:46-05:00
lastmod: 2023-07-10T02:25:46-05:00
weight: 70
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "🔎"
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

# What is this?
- Yet another AWS __managed service__
- Linked with LogStash and Kibana
- Logstash = storage; Kibana = dashboard

## - Formerly known as "AWS ElasticSearch"
- The "E" in the [ELK stack](https://www.elastic.co/what-is/elk-stack)
- May also be referred to as __AWS ES__

## What does it do?
- Log analytics; [OLAP](https://aws.amazon.com/what-is/olap/#:~:text=Online%20analytical%20processing%20(OLAP)%20is,smart%20meters%2C%20and%20internal%20systems.)
- Time series analysis
- IT Ops Monitoring

## Potential Inputs?
- LogFiles
- Messages
- Metrics
- Config Info
- Documents

## Potential Outputs?
- Search
- Security/event mgmt
- App monitoring
- Infra monitoring

## What's logstash?
1. Ingest data from search
2. Transforms it
3. Dumps it to a "stash" (storage of choice)