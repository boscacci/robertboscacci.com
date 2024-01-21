---
title: "Spotify MLOps Meetup Notes"
toc: false
date: 2023-06-22T02:25:46-05:00
lastmod: 2023-06-22T02:25:46-05:00
draft: false
Description: "Robert Boscacci is a data scientist and author. Sometimes he does freelance data analysis work. If you need some business data analyzed, you might consider hitting him up." # Keep to 150-160 chars
keywords:
 - Robert Boscacci
 - Data science
 - Data analysis
 - NYC
 - New York City
 - Spotify
 - Engineering
 - MLOps
---

<link rel="stylesheet" href="/css/custom.css">

On 2023-06-22 I attended the [NYC MLOps Community meetup at Spotify](https://mlops.community/event/nyc-mlops-community-meetup-spotify). Here are some photos and notes from the talks:

<div class="image-grid">
	<!-- Image with link -->
	<img src="https://live.staticflickr.com/65535/52995898729_8996897933_k.jpg"
	style="border: 3px solid black;"/>
	<img src="https://live.staticflickr.com/65535/52995758576_898b4743c8_k.jpg"
	style="border: 3px solid black;"/>
	<!-- Image with link -->
	<img src="https://live.staticflickr.com/65535/52996122560_3b1d70dfa6_k.jpg"
	style="border: 3px solid black;"/>
	<!-- Image with link -->
	<img src="https://live.staticflickr.com/65535/52995153352_e043ef2521_k.jpg"
	style="border: 3px solid black;"/>
</div>

<br/>

# David Xia: How to Build a Frictionless ML Platform

* Spotify uses [**ray**](https://www.ray.io/).
* End-user teams manage their own [ray clusters](https://engineering.atspotify.com/2023/02/unleashing-ml-innovation-at-spotify-with-ray/) on multi-tenant infra.
* **Hendrix** is a (beta) internal spotify tool to save folks from needing to learn K8s.
* How to solve local development problems?
	* Cloud developer environment (__CDE__).
	* They built something like GitHub codespaces, but with Ray and GPUs
	* VSCode in the browser: Works the same on any device
	* Everything runs as workloads on K8s
	* They use Istio to get routing done right
* Lessons Learned:
	* Must be HA: Don't have a reverse proxy that is a SPOF (single point of failure)
	* Needs to be customizable and extensible
	* Needs telemetry to show that the CDE actually makes people more productive
	* Use K8s etcd as your DB
	* Use K8s operator with CRD, it's neat

# Ryan Culbertson: Near Real-Time Features w/ Jukebox NRT
* Ryan:
	* Spotify senior engineer
	* ML Infra
	* Feature Mgmt tooling
* Ideally, the Spotify app makes personalized recommendations right after the user does stuff
	* Therefore, near real-time is desirable
* Cold-start problem is particularly challenging
* Near Real-Time (NRT) is just, like, streaming data that gets processed in minutes not seconds
* (Spotify runs all its stuff on Google Cloud)
* Scale: Operating on the order of like 3M messages/sec, high-cardinality too
* Their NRT tool __Jukebox__ uses Flink, Bigtable
	* Idea is to use SQL for experimentation and also prod
	* Jukebox operates in 5-min windows of aggregation
		* Small window: Fresh data
		* Big window: Cheap data
		* Had to find some arbitrary sweet spot
	* 5-minute window aggregations get re-aggregated on reads later
	* Some teams might want a 1-hour window, some might want 6-hour, etc.
* Lessons Learned:
	* Flink integration w/ GCloud needed custom connectors..! Probably smoother on the more mature Kafka
	* Instrument everything to help find bottlenecks (in multi-thread stuff, e.g.)