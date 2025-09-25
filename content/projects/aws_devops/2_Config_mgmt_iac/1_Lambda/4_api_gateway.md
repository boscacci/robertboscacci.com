---
title: "4: API Gateway"
date: 2023-07-05T02:25:46-05:00
lastmod: 2023-07-05T02:25:46-05:00
weight: 40
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What's this?"
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

## What is API Gateway?
- Make your own REST or websocket APIs
- Connect programmers (via HTTP GET and POST requests) to:
	- Lambdas
	- DynamoDB
	- Ec2
	- S3
	- Caches
	- Cloudwatch
	- Etc.

## REST vs Websockets?
- REST: 1-way comms; simple request/response
- Socket: 2-way comms; e.g. update the GUI as we go
	- Backend service can initiate comms
	- Real-time chat is one good example

## Authentication?
- Web identity federation stuff

## What about HTTP APIs?
- Cheaper and faster than REST
- Still lacking full functionality of REST
- Go with HTTP unless you need those extra functionalities

## What's Lambda Proxy Integration?
- You can __proxy requests as-is__ to lambda funcs 
- You can point API Gateway to lambda __aliases__
	- E.g. point to "prod" rather than "version 2"
- You have to __give API gateway permission__ to invoke a lambda function
	- The function has a __resource-based policy__ to allow this

## How is the API updated automatically?
- When you add an API to your function—
	- ...via lambda console,
	- ...via API gateway console,
	- ...or via SAM template,
- The resource-based policy is updated automatically.