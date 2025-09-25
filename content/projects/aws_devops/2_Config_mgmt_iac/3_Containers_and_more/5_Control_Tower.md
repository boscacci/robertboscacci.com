---
title: "5: AWS Control Tower"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 60
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Sauron"
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

# What's Control Tower?
- Set up and govern multi-account environments
- It's an extension of "AWS Organizations"
- Good for security and governance

# Why use it?
- Deploying apps to multiple accounts is a big paradigm in AWS
- Provides additional control / presets

# How's it work?
- Creates a multi-account baseline called a __landing zone__:
- LZ creates organizational units (OU's) and accounts for us
	- Security best practices are baked in already

# Etc.
- If you don't have an org, control tower will make one for you
- What's a landing zone? Look above.
- Two types of guardrails:
	- Preventative
	- Detective