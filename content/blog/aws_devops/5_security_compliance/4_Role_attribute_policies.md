---
title: "4: Role-based Vs. Attribute-Based"
date: 2023-07-11T02:25:46-05:00
lastmod: 2023-07-11T02:25:46-05:00
weight: 40
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Role/Attribute Policies"
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

## Drawbacks to role-based?
- complex logic
- dynamic authorization parameters
- unique users, multiple roles

## What's attribute-based access?
- Attributes can be associated w/ user, resource, env, or app state
- Very flexible, allowing dynamic, contextual decisions
- If an ID and a resource share an attribute...
	- Then the identity can access the resource

## Why are tags/ABAC so versatile?
- Tags are k:v pairs that can be anything