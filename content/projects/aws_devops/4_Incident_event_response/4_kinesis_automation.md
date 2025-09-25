---
title: "4: Kinesis Event-Driven Automation"
toc: false
weight: 40
draft: false
lastmod: 2023-07-11T02:25:46-05:00
related: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
  pass the aws devops professional certification by sharing his notes here."
summary: "How's it event response?"
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

# TL;DR Kinesis is event-driven too

# "Upstream events" need to be processed in real-time

## What can be used for event-driven arch?
- EventBridge
- Lambda
- **Kinesis** - for real-time

## What are keywords for kinesis?
- Real-time
- Big Data™️

## How can we chain kinesis stuff together?

1. "Streams" receives many sources
2. "Analytics" process in real-time
3. "Firehose" feed to bucket/DB

## How do we stream data to our "consumers?"
- Data streams