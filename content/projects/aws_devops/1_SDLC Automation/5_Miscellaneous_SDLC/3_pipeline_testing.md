---
title: "3: Pipeline Testing"
toc: false
date: 2023-06-26T02:25:46-05:00
weight: 40
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
Summary: "How to debug them"
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

## Where do we test?
- During __Build__, run:
	- Unit tests
	- Static analysis; code review
- During __staging/test__, run:
	- Integration tests: E.g. interaction of app w/ DB
	- Component: Test messaging between components
	- System: Test end-to-end system
	- Performance: Put a load on it
	- Compliance
	- Acceptance: Does the system meet biz goals?
- During __prod__ stage, run:
	- Everything from test, again
	- _Canary_

## Which type of test should comprise most of your testing?
- Unit tests. Roughly 70%.