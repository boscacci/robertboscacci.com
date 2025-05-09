---
title: "1: CodeCommit Details"
toc: false
lastmod: 2023-06-08T02:25:46-05:00
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

## Basic actions:
* Create repo:

```Shell
$ aws codecommit create-repository --repository-name rad-repo-name
```

* View a repo: `get-repository`
* List repos: `list-repositories`
* Delete repo(s)

```Shell
$ aws codecommit delete-repository --repository-name rad-repo-name
```

__Commands are pretty literal!__

## Data Security on CC:

* Data is encrypted __at rest__ (managed) AND __in transit__ (SSH, HTTPS)
* CodeCommit uses KMS to manage keys.
* No scale/availability-related security holes; it's managed
* "CodeCommit Power User" role gives full access, _minus_ create/delete repos
* Maybe not everyone should have permission to push to main..!

## Connecting:

You can use SSH or HTTP to interact with git repos on CodeCommit.

To use SSH, you have to tweak "SSH public keys for AWS CodeCommit" in IAM.
* Generate an SSH key pair on the dev box.
* Upload the SSH public key to IAM (codeCommit section for your user).
* Grab the new "SSH Key ID" from IAM - that's your "User" for SSH.
* Edit your ssh config file ("~/.ssh/config" on mac) to contain something like this:

```YAML
Host git-codecommit.*.amazonaws.com
    User SSH_KEY_ID_FROM_IAM
    IdentityFile ~/.ssh/id_rsa (or other private key loc)
```

## Misc. Git Fundamentals:

If you didn't already know, __branches__ are good for:
- Building new features
- Fixing bugs
- Separating work
- Without disrupting the main branch

More on common git workflows [on Atlassian's website](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow).