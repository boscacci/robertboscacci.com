---
title: "0: CloudFormation Overview"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 10
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "Overview"
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

# What is CF?
- Infrastructure as Code service
- Leverages version control and automation
- Single or multiple templates to make an env
- Can interact with other tools e.g. puppet
	- CF creates instances;
	- Puppet puts the instances in a certain state

# What sort of stuff can we update in the stack?
- AMI of instances
- Update a cloudwatch alarm
- Auto-scaling groups

# How do we update the stack?
1. Update the template
2. Update the stack with the new template

# What are stack policies good for?
- Perhaps you don't want just anybody updating the stack
- Preventing resource updates:
	- JSON documents
	- Similar to IAM and bucket policies

# Why might stack rollbacks fail?
- Nested stacks.
	- Dependencies between resources
	- Resource modified outside of template

# What's the CF Template?
- Declaration of resources that make up a stack
- Declares an __object__ as a name-value pair
	- Or a pair of name + enclosed objects
- The __"resource" object__ is the __only required object__ in the template

# What else is in a CF template?
- Metadata: Assists with config
- Parameters: Good for secrets
- Rules: Evaluate parameters
- Mappings: Map an instance type to a certain architecture, e.g.
- Conditions: Flags to dictate, say, size of server
- Transform: Sort of like an "import" statement. (Include lambdas)
- Resources: Define resources; the main thing
- Outputs: URL to the web server, e.g.

# How are CF templates a disaster recovery tool?
- You can store templates in a second region

# How do we safeguard template integrity?
- Use source control
- Use "drift detection"
	- Make sure templates match their backups between regions