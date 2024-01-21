---
title: "6: Nested Stacks / Cross-stack refs"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 16
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Keep it modular"
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
## Why nested stacks?
- Modularity
- Reusability
- Reuse smaller chunks of template in (perhaps hundreds of) parent templates
- More OOP-style

## Why cross-stack refs?
- Get diff teams working on different template files
- Export values from one stack to another related one
- More API-style

## How?

__Nesting:__
- Use `AWS::CloudFormation::Stack` resource

__Cross-stack:__
- Use cross-stack refs;
	- Use "output" section of templates
	- Use `Fn::ImportValue` to import outputs