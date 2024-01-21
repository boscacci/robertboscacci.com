---
title: "Case Study: Small Business Analysis"
toc: false
date: 2023-04-11T02:25:46-05:00
lastmod: 2023-04-11T02:25:46-05:00
draft: false
Description: "Robert Boscacci is a data scientist and author. Sometimes he does freelance data analysis work. If you need some business data analyzed, you might consider hitting him up." # Keep to 150-160 chars
keywords:
 - Robert Boscacci
 - Data scientist
 - Freelance
 - Contractor
 - Data analysis
 - NYC
 - Brooklyn
 - New York City
 - Consulting
---

🏡🌳🌴🌲🌴🌳🏡

A data analysis consulting project 🔎 for a tree trimming service

Project Start: Jan 03, 2023

Hours billed: 17

## Inbound Vector

My good friend (and former ally in cinema) [Winson](https://www.linkedin.com/in/winson-tam-b151a4128/) is connected to one of the [Barnes Brothers](https://barnes-brothers-tree-service-llc.business.site/). The Barnes run a busy tree trimming and removal service near Fayetteville, NC. 

Barnes expressed interest in __mining their invoicing and calendar data for business insights__. My name came up, because I do this sort of thing 👨‍💻. Winson made the connection, helped scope out the project parameters, budget, and deliverables, then left us to ourselves.

<!-- Image with link -->
<a href="https://barnes-brothers-tree-service-llc.business.site/">
	<img src="https://live.staticflickr.com/65535/52810020073_b6080f71c1_o.png"
	width="800"
	style="border: 1px solid black;"/>
</a>

## The Ask

* "Use Barnes Brothers's historical estimates 💵 and calendar events 🗓️ to __determine the most lucrative strategy and help focus their resources.__"

* "__Generate a report featuring a series of maps__ 🗺️📍showing acceptance rates of job estimates, average/median/mean earned amount by zip code, and __provide any insights__ supported by the data."

* "In a 10-15 minute meeting, help __go over the results__ 🎤 and highlight anything of value that supports one or more courses of action."

The client does invoicing and estimates in the cloud. Their job scheduling happens over shared google calendars. With at least high hundreds of jobs under their belts, they're set up to spot some actionable patterns in their billing and appointment data.

At the very least, I imagine I'll be able to aggregate data by zip code and client uid. I bet I could even use the address field to get accurate customer lat/long coordinates, perhaps to create a heatmap of fruitful micro-climates. 

The client could then target their promotional programs at those areas for maximal return. They'll know where to send the holiday fruit baskets, and where to cut back on low-growth areas.

## Available Data

* "From the extract the estimate's date, total amount, and customer address fields."

* "From Barnes Brothers' __Google calendar,__ extract the address field of calendar events with Green labels."

## Challenges

* In the billing software, not all job estimates materialize into paid/invoiced jobs
* The job scheduling calendar and billing software are two separate systems
* The "address" fields are the main join keys between billing & calendar

<iframe src="https://giphy.com/embed/1zTqgW6bS2jWU" width="480" height="343" frameBorder="0" class="giphy-embed" allowFullScreen></iframe>

## Approach

__1. Divide Work Into Stages__

Communicate plan and billing estimate to client for:
1. Data Collection (10hr)
2. Data Analysis (6hr)
3. Reports / Visualization (4hr)

__2. Data Collection__

- Client provides credentials for google cloud and "invoice simple"
- Invoice software lacks data export feature. Submit [feature request](https://help.invoicesimple.com/en/collections/3415033-features-and-settings)
- Write [Selenium](https://selenium-python.readthedocs.io/) scripts to log in and scrape invoice data to csv
- Make [GCP API](https://cloud.google.com/apis) calls to fetch green calendar event data
- Clean up data types and other housekeeping in [pandas](https://pandas.pydata.org/) / [jupyter](https://jupyter.org/about)

__3. Data Analysis__

- [Fuzzy string match](https://github.com/seatgeek/thefuzz) to find matching "address" fields between billing estimates and calendar events
- Datetimes further confirm or deny that certain estimates became invoiced, completed jobs
- Derive aggregate metrics e.g. confirmation rates and cumulative totals by zip, client
- Run addresses through [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/overview) to get lat/long for each address

__3. Reports/Viz__
- [Plotly](https://plotly.com/python/) to generate ordinary bar charts outlining top clients, high-conversion areas
- [kepler.gl](https://github.com/keplergl/kepler.gl) to visualize high-spend geographies. The maps look sort of like this:

![](https://camo.githubusercontent.com/5db578b8d383e96be752ab4b8c842a3192a384dbddc21561a28bc948704904a4/68747470733a2f2f656e672e756265722e636f6d2f77702d636f6e74656e742f75706c6f6164732f323031382f30352f696d616765342d332d373638783439332e706e67)

## Deliverables
- .html files with interactive kepler maps
- Clean source and aggregated data as .xlsx files
- 20-minute presentation of insights / slides

## Client Feedback
Positive!
![](https://live.staticflickr.com/65535/52810073321_3371779cd9_o.png)