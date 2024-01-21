---
title: "4: Kinesis"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 40
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Streaming Data"
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
- Real-time (streaming) data collection, processing, analysis
- React quickly to new information

## How many varieties of Kinesis exist?
- Four:
	- Video streams
	- Data firehose
	- Data streams
	- Data analytics

# Kinesis Flavors:

## Video Streams
- Stream video: Real-time viewing and video-enabled app
- E.g. smarthome stuff, computer vision, security
- Could be streamed to Rekognition, for example
- Encrypt, index streams of video

## Data Firehose
- Dump streaming data into data lakes, warehouses
- Streaming machine learning applications
- Deliver real-time streaming data to s3, redshift, OpenSearch...
- IoT Devices?

## Data Streams
- __Ordering__ of records; streaming __and manipulation__ of data
- Scalable, durable
- Can handle gigabytes per second
- E.g. click streams from websites, transactions
- Collect streaming data / big data for OLAP

## Data Analytics
- __Analyze__ streaming data for actionable insights
- Log analytics with SQL
- Receive from Data Streams ^