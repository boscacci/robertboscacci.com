---
title: "5: Updating CF Stacks"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 15
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How do we roll out updates?"
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
## How does one update a CF stack?
(Say we need to size up our ec2 instance)
1. Submit updated template
2. CF compares changes
3. Only changed resources are changed

__Ways:__

1. "Direct Update" (just go for it)
2. "Change set" (Gives ability to do a dry-run / preview)

# Potential update behaviors?

__(Varies by resource type)__

## 1. Update w/ no interruption
- Updates resource w/o disrupting ops nor physical ID
- E.g. Instance profile

## 2. Update w/ some interruption
- Updates w/ some interruption. Physical ID retained
- E.g. HostId 

## 3. Replacement
- Total recreation / new physical ID.
- E.g. availability zone

## Direct changes or change sets?
- Change sets are good for prod
- Direct is fine for dev or test

## How to utilize update behaviors?
- Dictates how to modify resources
- Don't do a full "replacement" if you need to retain physical ID[label](4_CF_stack_protection.md)