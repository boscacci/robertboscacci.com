---
title: "0: Incident / Event Response Overview"
date: 2023-07-10T02:25:46-05:00
lastmod: 2023-07-10T02:25:46-05:00
weight: 01
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "General notes on incident response"
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
## What's in here?
- Troubleshooting
- Restoring operations
- Automating event mgmt + alerting
- Implement automated healing
- Event-driven automated actions

## Which Whitepapes to Study?
- [AWS Security Incident Response Guide](https://docs.aws.amazon.com/whitepapers/latest/aws-security-incident-response-guide/aws-security-incident-response-guide.html)
- [AWS Security best practices](https://aws.amazon.com/architecture/security-identity-compliance/?cards-all.sort-by=item.additionalFields.sortDate&cards-all.sort-order=desc&awsf.content-type=*all&awsf.methodology=*all)

## Related Services?
- CloudWatch: Detect issues, automate events
	- Monitoring thresholds trigger events
- OpsWorks (stacks): Auto-heal failed instances
	- (It's in stack layer settings)
- Auto-scaling: Monitor metrics (scale or heal instances)
- CloudFormation: Store templates in multiple regions for redundancy
- __AWS Health Dashboard__: Availability and Operations of services