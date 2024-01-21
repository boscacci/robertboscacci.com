---
title: "3: CloudFormation Helper Scripts"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 13
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "CFN-init, signal, hup, get-metadata"
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
## What are CF helper scripts?
- __Python scripts__ to install software and start services on ec2 boxes
- Called directly from CF template
- Work with __resource metadata__ defined in template
- Send signals back to the stack

## cfn-init
- Retrieve and interpret resource metadata
- Install packages, create files, start services
- e.g. start web server

## cfn-signal
- Signal between wait condition and the stack what's going on
- Is the stack ready to continue build/update?
- Used with both wait conditions and creation policies

## cfn-hup
- Continuously running daemon
- Checks for updates to metadata
- Executes custom hooks when changes detected
- Has an arg to make it run once then exit without daemon'ing

## cfn-get-metadata
- Retrieve all metadata for a resource, or:
- Retrieve path to specific key or subtree of resource data
- Good for troubleshooting