---
title: "Elliott Bay Marine VHF Monitor"
showTableofcontents: true
date: 2026-05-27T17:45:00-07:00
lastmod: 2026-06-29T00:00:00-07:00
draft: false
description: "A home-lab marine VHF monitor with SDR capture, browser-playable live audio, AIS, searchable clip transcripts, BERTopic transcript clusters, and ongoing Whisper transcription work."
summary: "Live Elliott Bay VHF audio, AIS, searchable clips, BERTopic transcript clusters, and ongoing Whisper transcription work. Built with help from OpenAI Codex."
featureUrl: "https://media.robertboscacci.com/photos/elliott-bay-vhf/app-live-monitor.png"
featureAlt: "Live Monitor screenshot from the Elliott Bay Marine VHF web interface."
keywords:
 - Robert Boscacci
 - Software engineering
 - Raspberry Pi
 - RTL-SDR
 - Marine VHF
 - Elliott Bay
 - VHF radio
 - Transcription
 - OpenAI Codex
 - Whisper ASR
 - AIS
 - AWS
 - OpenTofu
---

This project monitors nearby Elliott Bay marine VHF radio traffic. A Raspberry Pi radio edge captures VHF audio and AIS, an Ubuntu micro-computer at home processes clips and transcripts, and AWS serves browser-playable live audio, vessel positions, searchable clips, "Hall of Fame" audio, and transcript analysis with word charts, entity counts, and BERTopic clusters.

I used OpenAI Codex while building and deploying it. The transcription work uses Whisper; reviewed corrections feed an experimental fine-tuning workflow for maritime radio audio, vessel names, channel jargon, and Seattle Traffic phrasing.

- Production: [seattleboatradio.com](https://seattleboatradio.com/)
- Development: [dev.seattleboatradio.com](https://dev.seattleboatradio.com/)
- Source: [boscacci/vhf-seattle](https://github.com/boscacci/vhf-seattle)

_Some hardware links below are Amazon affiliate product links. As an Amazon Associate I earn from qualifying purchases._

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a [Uniden MHS75 handheld marine radio](https://www.amazon.com/dp/B001J5MQ20?tag=robertboscacc-20). Instead, I decided it would be more useful and more interesting to connect an [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20) to a [Raspberry Pi 4 starter kit](https://www.amazon.com/dp/B07V5JTMV9?tag=robertboscacc-20) and do computer-based processing with the audio.

## Screenshots

The public interface has views for clips, live monitoring, transcript search, word/entity analysis, and BERTopic transcript clusters.

Desktop captures:

<div class="vhf-screenshot-gallery">
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-clip-review.png" alt="Production Clips desktop screenshot for Elliott Bay VHF">
    <figcaption>Clips.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-live-monitor.png" alt="Production Live Monitor desktop screenshot for Elliott Bay VHF">
    <figcaption>Live Monitor.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-search.png" alt="Production Search desktop screenshot for Elliott Bay VHF">
    <figcaption>Search.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-analysis-channel-bars.png" alt="Analysis dashboard bar chart of analyzed transcript clips by VHF channel for Elliott Bay VHF">
    <figcaption>Analysis.</figcaption>
  </figure>
</div>

![BERTopic transcript cluster animation for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/topic-clusters.gif)

_BERTopic transcript cluster view._

Mobile captures:

<div class="vhf-screenshot-gallery vhf-screenshot-gallery--mobile">
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/mobile-clip-review.png" alt="Production Clips mobile screenshot for Elliott Bay VHF">
    <figcaption>Clips.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/mobile-live-monitor.png" alt="Production Live Monitor mobile screenshot for Elliott Bay VHF">
    <figcaption>Live Monitor.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/mobile-search.png" alt="Production Search mobile screenshot for Elliott Bay VHF">
    <figcaption>Search.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/mobile-analysis.png" alt="Production Analysis mobile screenshot for Elliott Bay VHF">
    <figcaption>Analysis.</figcaption>
  </figure>
</div>

## Architecture

The system has three runtime layers:

- **Raspberry Pi radio edge** ([Raspberry Pi 4 starter kit](https://www.amazon.com/dp/B07V5JTMV9?tag=robertboscacc-20)): VHF voice capture, AIS decode, live audio publishing, activity detection, and bounded local buffers.
- **Ubuntu micro-computer:** private API, raw-audio uploads, transcription, transcript corrections, public exports, and telemetry.
- **AWS public edge:** private S3 origins, CloudFront, DynamoDB, API Gateway/Lambda for AIS, ACM, and Route 53.

The public site reads from AWS. It does not connect directly to the Pi, the home server, LAN Icecast URLs, Tailscale Funnel origins, raw S3 objects, or DynamoDB. Write-capable operator tools stay on the private/dev path over the tailnet.

SQLite is retained only for explicit legacy backfills, local fixtures, and separate realtime telemetry.

![Production boundary diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/production-boundary.png)

_Current production boundary._

## Radio And Live Paths

Radio capture:

- A [Bingfu VHF/UHF antenna kit](https://www.amazon.com/dp/B0CLKLHHNP?tag=robertboscacc-20), an [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20), and a dAISy-catcher receiver feed the Raspberry Pi.
- RTLSDR-Airband monitors a 12-channel marine VHF profile: 05A, 06, 09, 13, 14, 16, 22A, 67, 68, 69, 71, and 72.
- VHF 14 remains the default live feed for Seattle Traffic / Puget Sound VTS.
- AIS-catcher now runs from the dAISy-catcher over USB serial around 162 MHz.

Major shout-out to [Adrian Studer](https://github.com/astuder) and [Jasper](https://github.com/jvde-github) for building the dAISy-catcher and mailing me one for free. It immediately replaced the old AIS RTL-SDR path and started pulling in a much healthier local vessel picture.

Live audio:

- The Pi publishes local Icecast output to the private home processing path.
- The Ubuntu micro-computer exposes a narrow read-only live proxy for the public edge.
- CloudFront serves same-origin live paths such as `/api/live/current.mp3`, `/api/live/channels`, and per-channel streams such as `/api/live/14/current.mp3`.

AIS:

- AIS-catcher decodes vessel messages on the Pi.
- A local forwarder sends sanitized-bound input to API Gateway over outbound HTTPS.
- Lambda strips private fields and bounds the public payload to local waters.
- Public reads use the same-origin `/ais-catcher/` viewer path and `wss://ais-live.robertboscacci.com/v1`.

## Processing Path

Clip processing:

- The Pi creates activity clips and sidecar metadata, then asks the private API for short-lived upload URLs.
- Raw audio stays in private S3.
- DynamoDB stores clip events, transcripts, corrections, and serving read models.
- The Ubuntu micro-computer runs `faster-whisper`, review/correction workflows, transcript analysis, and public exports.

Retention and export:

- Unstarred raw `raw/` audio expires after 90 days.
- Starred "Hall of Fame" clips are tagged for longer retention.
- Public exports strip private fields, raw keys, internal URLs, account IDs, and nondisplayable transcript artifacts.
- Playback controls are shown only when public audio can still be resolved.

![Whisper fine-tuning feedback loop diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/whisper-fine-tuning.png)

_Whisper fine-tuning feedback loop._

## Deployment And Infrastructure

Infrastructure is managed with OpenTofu:

- Separate dev/prod static-site buckets.
- Separate dev/prod private raw-audio buckets.
- Separate DynamoDB event tables.
- CloudFront Origin Access Control for private S3 origins.
- API Gateway/Lambda AIS ingest and WebSocket delivery.
- ACM certificates, Route 53 records, and scoped IAM policies.
