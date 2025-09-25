---
title: "1: CloudWatch Logs / Metrics"
date: 2023-07-08T02:25:46-05:00
lastmod: 2023-07-08T02:25:46-05:00
weight: 10
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What's the difference?"
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

## What are Metrics
- They can be customized to suit our needs
- e.g. memory utilization
- Metric filters: Define which metrics to extract and pub to cloudWatch

## What's a "namespace"?
- Used to isolate diff apps and metrics
- Naming convention for namespaces:
	- EBS - AWS/EBS
	- ELB - AWS/ELB
	- EC2 - AWS/EC2

## Key elements for filtering metrics?
1. Filter pattern
2. Metric name
3. Namespace
4. Metric value
- e.g. counting 404 errors = value of 1 for each error

## What are logs?
- Log events: The activity being reported
- Log streams: A source of log events from the same source
- Log group: Log events with the same properties, policies, access controls
- E.g. logfiles on ec2 from log agent

## Are cloudWatch logs automatically encrypted at rest?
- Yes!

## What about log group data? Encrypted?
- Yes!

## Does CloudWatch Logs manage server-side encryption keys?
- Yes!

## What if you need to manage the encryption keys manually?
- Use "customer master keys" in KMS

## What's the "Log Agent"?
- Agent we can install on ec2 to auto-pub log events to cloudWatch
- Can be on beanstalk, CF, OpsWorks ec2 instances
- Installed via AWS API, CLI, or SDK's (e.g. boto3)
- Monitors a log file, sends it out

## Do cloudwatch metrics go cross-region?
- No.

## How long before CloudWatch metrics expire?
- 15 months, if no new data is published to a metric

## What are cloudWatch "periods"?
- Control what's aggregated in stats
- Can be used for alarms

## What are CloudWatch "dimensions"?
- Name/value pair uniquely identifying a metric
- e.g.:
	- ec2 InstanceId
	- ec2 InstanceType
	- ec2 AutoScalingGroupName
	- ELB AvailabilityZone
	- ELB loadBalancerName

## Diff between metrics and logs?
- E.g. in a load balancer:
	- Metrics: Time-series data points about the __elb stats__; regular intervals
	- Logs: Info __regarding requests__ to the load balancer; event-specific