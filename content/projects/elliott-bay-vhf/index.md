---
title: "VHF Chatter in Elliott Bay"
showTableofcontents: true
date: 2026-05-27T17:45:00-07:00
lastmod: 2026-06-02T23:53:51-07:00
draft: false
description: "A home-lab marine VHF listening project with Raspberry Pi radio capture, OptiPlex processing, DynamoDB clip state, live audio, clips, transcript search, and analysis."
summary: "Live Elliott Bay marine VHF capture with recent clips, transcripts, search, Hall of Fame, and language analysis."
keywords:
 - Robert Boscacci
 - Software engineering
 - Raspberry Pi
 - RTL-SDR
 - Marine VHF
 - Elliott Bay
 - VHF radio
 - Transcription
 - AWS
 - OpenTofu
---

This project captures nearby Elliott Bay marine VHF radio traffic and publishes a read-only web interface with live audio, recent clips, transcripts, transcript search, Hall of Fame clips, and language analysis. The production site is [vhf.robertboscacci.com](https://vhf.robertboscacci.com/), the development site is [vhf-dev.robertboscacci.com](https://vhf-dev.robertboscacci.com/), and the source repo is [boscacci/vhf-seattle](https://github.com/boscacci/vhf-seattle).

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a handheld marine radio. Instead, I decided it would be more useful and more interesting to connect a receiver to a Raspberry Pi and do computer-based processing with the audio.

## Current Shape

The system has three main runtime layers:

- Raspberry Pi radio edge near the antenna and RTL-SDR receivers
- Used Dell OptiPlex desktop repurposed as a small Ubuntu home server
- AWS public edge using private S3 buckets, DynamoDB, CloudFront, ACM, and Route 53

The Raspberry Pi handles radio work that needs to stay close to the antenna: voice-channel demodulation, AIS decode, live MP3 streams, squelch and activity gates, split-on-transmission clip files, sidecar metadata, and bounded local buffers. It does not hold long-lived AWS credentials.

The OptiPlex is a secondhand office desktop originally bought as a Windows box and repurposed with Ubuntu. It runs the private API, presigns raw-audio uploads, runs transcription and export jobs, serves the read-only live proxy, and handles normal development and operations work.

AWS stores durable state and serves the public edge. Raw audio lives in private S3 buckets. DynamoDB stores clip metadata, status transitions, transcripts, transcript corrections, and serving read models. CloudFront serves the production static app from private S3 and routes narrow read-only live/API paths to the OptiPlex proxy.

SQLite is no longer the operational clip or transcript store. It remains for explicit legacy backfills, local fixture tests, and separate realtime performance telemetry.

![Production boundary diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/production-boundary.png)

_Production boundary diagram showing public read-only routes, tailnet operator routes, local runtime services, and AWS durable stores._

## Radio And Capture Path

The voice capture path is:

- Antenna to RTL-SDR receiver
- RTL-SDR receiver to Raspberry Pi
- Raspberry Pi capture services to local spool files and selected Icecast live streams
- Raspberry Pi spool uploader to the OptiPlex private API
- OptiPlex private API to private S3 and DynamoDB
- OptiPlex export jobs to the public S3/CloudFront site

The current balanced voice profile uses RTLSDR-Airband to monitor these marine VHF channels in one multichannel process:

- 05A, VTS / Port Ops
- 06, Intership Safety
- 09, Calling / Commercial
- 13, Bridge-to-bridge
- 14, VTS / Seattle Traffic
- 16, Distress / Calling
- 22A, USCG Liaison
- 67, Commercial / Bridge
- 68, Recreational
- 69, Non-commercial
- 71, Non-commercial
- 72, Ship-to-ship

Browser-facing live streams are narrower than the captured channel set. The public live routes expose selected channel streams, including VHF 13, VHF 14, VHF 16, and VHF 68. The stable `/api/live/current.mp3` route keeps VHF 14 as the default live feed.

![Production Live Monitor screenshot for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/app-live-monitor.png)

_Production Live Monitor view showing the default feed, queue state, waveform area, and monitored channel buttons._

A second RTL-SDR can run AIS-catcher around 162 MHz. The AIS map is available on dev/local paths only; the production site does not expose the AIS viewer.

## Processing Path

The Raspberry Pi applies the cheap, realtime processing first: demodulation, squelch, speech-band cleanup, split-on-transmission file output, and short local rolling buffers. Completed spool files are uploaded through the OptiPlex private API using short-lived presigned S3 URLs.

The OptiPlex records clip state in DynamoDB, retries incomplete uploads, runs `faster-whisper` transcription, stores transcript segments and corrections, and generates public exports. The public export copies safe audio files, removes private fields, skips very short or nearly silent clips, filters low-confidence transcript artifacts, and preserves the analysis artifacts used by the public app.

Unstarred raw audio in the private S3 `raw/` prefix expires by lifecycle rule after 90 days. Starred Hall of Fame clips are tagged for longer retention.

![Durable clip lifecycle diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/durable-clip-lifecycle.png)

_Durable clip lifecycle diagram showing private ingest, DynamoDB and raw S3 state, transcription/review, sanitized export, and public read-only delivery._

## Public Boundary

The production site is public and read-only. It exposes static app assets, published clip metadata, short-lived playback URLs, live audio/status routes, transcript search, and language-analysis data.

It does not expose radio controls, retune endpoints, ingest endpoints, raw S3 object keys, presigned URLs, private database access, long-lived credentials, LAN Icecast URLs, the AIS viewer, performance telemetry, or the Raspberry Pi's local services.

The public live/API paths are routed through CloudFront to a read-only OptiPlex proxy exposed by Tailscale Funnel. Dev and local hosts can expose additional operator surfaces, including transcript correction, clip starring, AIS, and performance checks.

## Deployment And Infrastructure

Infrastructure is managed with OpenTofu. The AWS layer uses separate dev and production static-site buckets, separate raw-audio buckets, separate DynamoDB event tables, CloudFront Origin Access Control, TLS certificates, DNS records, and server IAM policies.

Development deploys go to a separate dev S3 origin and are served behind `vhf-dev.robertboscacci.com` through the OptiPlex tailnet path. Production deploys go to the production S3 origin and CloudFront distribution behind `vhf.robertboscacci.com`. The deploy helper only allows production from a clean `main` worktree.

## Current Outputs

The current public interface includes these views:

- Clip Review for recent public clips, transcript text, playback controls, per-channel filtering, and Hall of Fame filtering
- Live Monitor for the default VHF 14 feed and selected per-channel live audio/status routes
- Search for finding clips by transcript meaning
- Analysis for lexical-analysis JSON, topic output, entities, and related language summaries

![Production Clip Review screenshot for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/app-clip-review.png)

_Production Clip Review view showing recent transcripts, playback controls, channel filtering, page size controls, and Hall of Fame filtering._

![Production Search screenshot for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/app-search.png)

_Production Search view showing transcript search controls and generated search starters._

![Production Analysis screenshot for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/app-analysis.png)

_Production Analysis view showing analyzed transcript counts, channel distribution, and topic-model summary._

Development and local operator views also support transcript correction, clip starring, performance telemetry, and AIS map checks.
