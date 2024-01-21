---
title: "0: Elastic Beanstalk Overview"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 01
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "General notes on elastic beanstalk"
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

## Why Beanstalk?
* __Quickly deploy__ apps w/o worrying about infra
* __Easy upload__ application
* Geared towards software developers
* Works with containers!
* Great for testing environments

## How beanstalk?
* Create "application"
	- Environments
	- Versions
	- Configuration
* Upload "version"
	- Bundled app
* Launch environment
	- AWS resources running a version
* Manage environment
* (Upload new versions)

## Drawbacks of beanstalk?
* Less customizable under the hood

## Alternatives?
* OpsWorks
	- Config mgmt service
	- __Chef, puppet__ instances
	- Hybrid environments, on-prem servers reachable by chef/puppet
* CloudFormation
	- More about infra than apps
	- Can actually be used to deploy OpsWorks and Beanstalk stuff
	- I.e. _works with beanstalk_.