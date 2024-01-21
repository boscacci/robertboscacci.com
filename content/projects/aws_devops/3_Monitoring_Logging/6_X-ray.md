---
title: "6: AWS X-Ray Concepts"
date: 2023-07-10T02:25:46-05:00
lastmod: 2023-07-10T02:25:46-05:00
weight: 60
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "🩻"
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
- Useful in microservices environment
- Good for troubleshooting, performance tuning
- X-ray daemon sits on servers and __monitors requests__
- X-ray gives a GUI __node graph view__ of request flows
- Detailed info about requests/responses, calls to __downstream resources__

## Study Notes:
- X-ray analyzes and debug __distributed apps__ / __microservices__
- __"End to end"__ is a keyword
- Find issues + __optimize__

## What's an x-ray "trace"?
- A set of datapoints sharing a __trace ID__

## What's an x-ray "segment"?
- Holds data for a __single component__ of an app

## Color Coding
- Green: Success
- Red: Server faults
- Yellow: Client errors
- Purple: Throttling errors