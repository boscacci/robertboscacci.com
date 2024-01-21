---
title: "4: CloudFormation Stack Protection"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 14
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "How do we keep prod from being fragile?"
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
## How do we prevent accidental stack deletion/updates?
1. Termination protection
2. Stack-level policies
3. Resource-level policies
4. IAM Policies

## Termination Protection
- Enable when creating the stack
- Delete actions will be denied
- Protection flows from parent stack to child stax
- You can just turn off protection to delete the stacc

## IAM Policies
- Same as everywhere else:
1. Make groups (admins, lead devs)
2. Define roles (permission boundaries)
3. Assign roles to groups

## Deletion Policies
- Preserve or back up individual __resources__ when stack deleted

## Stack-Level Policies
- JSON doc defining resources AWS CloudFormation can update during stack ops (create, update, and delete)
- Prevent updates that would delete or replace certain critical resources
- Example stack-level policy:
```
{
  "Statement" : [
    {
      "Effect" : "Deny",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "LogicalResourceId/MyDBInstance"
    },
    {
      "Effect" : "Allow",
      "Action" : "Update:*",
      "Principal": "*",
      "Resource" : "*"
    }
  ]
}

```