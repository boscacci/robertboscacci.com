---
title: "1: CloudFormation Intrinsic Functions"
date: 2023-07-06T02:25:46-05:00
lastmod: 2023-07-06T02:25:46-05:00
weight: 11
Description: "Robert Boscacci is a devops engineer. He wants to help you \
pass the aws devops professional certification by sharing his notes here." # Keep to 150-160 chars
summary: "What are they?"
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
## Ref
- Returns the value of the specified parameter or resource
- Json: `{ "Ref" : "logicalName" }`
- Yaml: `!Ref logicalName`

## Fn:FindInMap
- It's a hashmap lookup.
- Find e.g. AMI for a type of instance in a certain region

## What are CF intrinsic functions?
- Built-in funcs to dynamically assign values to properties at runtime
- E.g. retrieve public IP of ec2 instance in the stack __at runtime__

## Fn::GetAtt
- Returns value of an attribute from a resource
- JSON: `Fn::GetAtt: [logicalNameOfResource, attributeName]`

## Fn::ImportValue
- Returns __value of an output__ exported by another stack
	- (Cross-stack reference)
- Values are spit out from "output" section of another stack
- JSON: `"Fn::ImportValue" : {"Fn::Sub" : ${NetworkStackNameParameter}-SecurityGroupID"}`

## Fn::Sub
- String substitution builder
- JSON: `{"Fn::Sub": ["www.${Domain}", {"Domain": {"Ref": "RootDomainName"}}]}`

## Fn::Join
- Concatenate strings
- Yaml: `!Join [ "/", ["s3://mybucket", !Ref myfolder, "myfile.txt" ] ]`
- Result: `"s3://mybucket/myFolderValue/myfile.txt"`

## Condition Funcs
- Boolean operators: And, or, if, not, equals
- If prod: Beefy server, if dev: scrappy box
- Create or not create resources based on conditions