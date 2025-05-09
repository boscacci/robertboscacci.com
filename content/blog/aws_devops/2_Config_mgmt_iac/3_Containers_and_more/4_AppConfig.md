---
title: "4: AWS AppConfig"
date: 2023-07-07T02:25:46-05:00
lastmod: 2023-07-07T02:25:46-05:00
weight: 50
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Not CodeDeploy"
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

# What's AppConfig?
- It's part of __Systems Manager__
- Create, manage, quickly deploy app configs (duh)

Let's say you're developing an e-commerce web application that has a feature for promotional discounts. Every so often, you change these promotional discounts based on various factors like holidays, inventory, season, etc. These changes affect how your application behaves, and traditionally, to make these changes, you might have to make a code change and redeploy your application, which can be risky and time-consuming.

Instead, you could use AWS AppConfig to manage the promotional discounts as a configuration outside of your application code. This configuration could include variables like `discount_rate, start_date, end_date, items_on_sale,` etc.


# How is it different from CodeDeploy?
- CodeDeploy rolls out __new versions__ of existing apps
- AppConfig applies config changes to __running apps__
- Sort of circumvents SDLC pipeline

# Why use it?
- Reduce errors in app configs
- Update apps without interruption
- Control deployment of changes across apps
- Deploy changes across a range of targets
	- Containers
	- Lambda
	- Ec2

# Use Cases?
- Introduce changes to apps and test with prod traffic
- Turn on new features during product launch or announcement
- Allow premium subscribers to access paid content
- Reduce stress on apps when a dependency impacts the system