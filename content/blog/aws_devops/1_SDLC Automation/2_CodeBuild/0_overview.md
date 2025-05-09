---
title: "0: CodeBuild Overview"
toc: false
lastmod: 2023-06-08T02:25:46-05:00
weight: 10
draft: false
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
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

## What is it?

* CI service, fully managed (no maintaining build servers)
* Compiles source code
* Runs tests
* Prepackaged build environments for common langs
* Produces software packages ready-to-deploy (__"artifacts"__)
	* E.g. for java, a .jar file
	* Artifacts __land in S3__

## Do we need codebuild if it's not a compiled lang?

* Perhaps not
* Maybe we don't need a build stage for e.g. HTML or Python

## What are we charged for?

* Just when builds are running.

## How can we access CodeBuild?

* Console
* CLI
* SDK
* CodePipeline