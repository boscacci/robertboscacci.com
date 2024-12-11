---
title: "Computer Vision Project: Film Slate Detector"
showTableofcontents: false
date: 2023-05-25T02:25:46-05:00
lastmod: 2023-05-25T02:25:46-05:00
draft: false
Description: "Robert Boscacci is a data scientist and author. He knows how to fine-tune an object detection computer vision model. He used this ability to make a film slate detector." # Keep to 150-160 chars
keywords:
 - Robert Boscacci
 - Data science
 - Data analysis
 - Consulting
 - Computer vision
 - Film slate
 - Object detection
---

🎬 🎥 💻 A computer vision (object detection) pet project 👨‍💻 🍿 🎤

<iframe width="850" height="400" src="https://www.youtube.com/embed/KF4WEupeTAg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe><br/>

## Why

Back in ~2016-2018 I used to spend many, many hours in a dark room in SoHo scrubbing through video files to see where the slate claps were, so that I could fix the audio sync. It got very boring, to the point where I quit to go learn how to code.

## What

Why not have AI automate the boring stuff? Given enough labeled examples, a pre-trained image model should be able to spot slates, after some fine-tuning. I achieved a COCOmetric of like 88% with a few hundred images. It's just a fine-tuned faster-rcnn model.

The natural next step would be to train it on two classes: "Open" and "closed" slates, so that you could find the inflection point where the slate goes from open to closed. That might save some dailies technicians a lot of time.

## Tools

My data science mentor pointed me to [IceVision](https://github.com/airctic/icevision), [FastAI](https://course.fast.ai/), and various [TIMM models](https://huggingface.co/docs/hub/timm). I got set up with [LabelStudio](https://labelstud.io/) and [Weights and Biases](https://wandb.ai/site). I wrote a [long LinkedIn post](https://www.linkedin.com/posts/rboscacci_icevision-activity-6993242508814090240-aFeq?utm_source=share&utm_medium=member_desktop) about how I accomplished the fine-tuning.

In case you didn't already know, it can be incredibly frustrating to do data-intensive machine learning stuff on an Apple Silicone laptop. Rather than swapping out my local hardware, I took this opportunity to get really dirty with Ec2 spot instances and used Terraform to make it dead simple to spin up and tear down spot GPU instances.
