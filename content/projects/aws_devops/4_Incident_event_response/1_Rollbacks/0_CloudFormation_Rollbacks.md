---
title: "0: CloudFormation Rollbacks"
date: 2023-07-10T02:25:46-05:00
lastmod: 2023-07-10T02:25:46-05:00
weight: 10
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: " "
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
# Why do Stacks Fail?
- Insufficient permissions (IAM error)
	- Need permissions for all the resources involved!
- Limits exceeded: Too many instances, e.g.
- So many possible reasons

# Why would a rollback fail?
- Drift
	- e.g. rolling back to an old (deleted) DB instance
- Not using drift detection
- Trying to delete parent stack before children in nested stacks

# Troubleshooting Stack Failures:
- Study the messages during stack creation
- If EC2 issues:
	- Study cloud-init
	- Study logs in /var/log
	- Install cloudWatch logs agent, publish logs
- If one resource is being persnickety:
	- Put it in `RetainResources` param
	- Delete stack; resource will be retained
	- Delete resource individually
- S3:
	- Non-empty buckets won't delete