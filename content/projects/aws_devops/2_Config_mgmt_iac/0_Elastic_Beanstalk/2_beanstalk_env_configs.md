---
title: "2: Beanstalk Env Configs"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 03
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Knobs and Dials for Beanstalk"
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

# How to config EB env?
- Folder to use: __.ebextensions__
	- Filetype: `.config`
- Config files are __yaml or json__ format
- Cloudformation is our friend here too
	- In fact, using EB = just making a CF stack
	- We can have EB in a CF template
- You can also recycle saved configs
- You can also specify direct changes in the console/CLI

## Don't forget:
# .ebextensions