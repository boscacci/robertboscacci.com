---
title: "6: AWS Detective"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 70
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Sherlock"
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

# What's Detective?
- Helps analyze/investigate root cause of __security findings__
- Helps dig deeper into suspicious activity
- Analyze data up to a year old
- Collects log data from all over
	- Uses ML, stats, and graph theory to assess stuff

# What does it interact with?
- GuardDuty
- Security Hub

# What does it look at?
- Login attempts
- API calls
- VPC flow logs
- EKS audit logs
- Network traffic
- Findings detected by GuardDuty

# Do I need to enable GuardDuty first?
- Yes, two days before you can hope to use Detective

# How does Detective work at scale?
- You can have up to 1200 accounts
- AWS orgs can integrate with detective
- Admin account can centrally manage detective behavior graph DB