---
title: "Elliott Bay Marine VHF Monitor"
showTableofcontents: true
date: 2026-05-27T17:45:00-07:00
lastmod: 2026-06-04T11:41:45-07:00
draft: false
description: "A home-lab marine VHF listening project with Raspberry Pi radio capture, OptiPlex processing, AWS HLS live audio, AIS, DynamoDB clip state, transcript search, and analysis."
summary: "Live Elliott Bay marine VHF capture with HLS live audio, AIS, recent clips, transcripts, search, Hall of Fame, and language analysis."
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

This project captures nearby Elliott Bay marine VHF radio traffic and publishes a read-only web interface for live audio, AIS vessel positions, recent clips, transcripts, search, Hall of Fame clips, and language analysis.

- Production: [vhf.robertboscacci.com](https://vhf.robertboscacci.com/)
- Development: [vhf-dev.robertboscacci.com](https://vhf-dev.robertboscacci.com/)
- Source: [boscacci/vhf-seattle](https://github.com/boscacci/vhf-seattle)

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a handheld marine radio. Instead, I decided it would be more useful and more interesting to connect a receiver to a Raspberry Pi and do computer-based processing with the audio.

## Screenshots

The public interface has views for clip review, live monitoring, transcript search, language analysis, and transcript topic clustering.

Desktop captures:

<div class="vhf-screenshot-gallery">
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-clip-review.png" alt="Production Clip Review desktop screenshot for Elliott Bay VHF">
    <figcaption>Clip Review.</figcaption>
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
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-analysis.png" alt="Production Analysis desktop screenshot for Elliott Bay VHF">
    <figcaption>Analysis.</figcaption>
  </figure>
</div>

Mobile captures:

<div class="vhf-screenshot-gallery vhf-screenshot-gallery--mobile">
  <figure>
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/mobile-clip-review.png" alt="Production Clip Review mobile screenshot for Elliott Bay VHF">
    <figcaption>Clip Review.</figcaption>
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

![Transcript topic cluster animation for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/topic-clusters.gif)

_Transcript topic cluster view._

## Architecture

The system has three runtime layers:

- **Raspberry Pi radio edge:** VHF voice capture, AIS decode, HLS segment generation, activity detection, clip spooling, and bounded local buffers.
- **OptiPlex home server:** private API, presigned raw-audio uploads, transcription, transcript corrections, public export generation, and telemetry.
- **AWS public edge:** private S3 origins, CloudFront, DynamoDB, API Gateway/Lambda for AIS, ACM, and Route 53.

Boundary decisions:

- Public browser reads terminate at AWS edges.
- The OptiPlex is private/dev infrastructure, not a production website origin.
- The Pi publishes outbound only, using scoped cloud resources.
- Dev/operator paths can reach the OptiPlex private API over the tailnet for write-capable actions.
- SQLite is retained only for explicit legacy backfills, local fixtures, and separate realtime telemetry.

![Production boundary diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/production-boundary.png)

_Current production boundary._

## Radio And Live Paths

Radio capture:

- Antenna and RTL-SDR receivers feed the Raspberry Pi.
- RTLSDR-Airband monitors a 12-channel marine VHF profile: 05A, 06, 09, 13, 14, 16, 22A, 67, 68, 69, 71, and 72.
- VHF 14 remains the default live feed for Seattle Traffic / Puget Sound VTS.
- A second RTL-SDR runs AIS-catcher around 162 MHz.

Live audio:

- The Pi converts local Icecast output into short HLS playlists and segments.
- HLS objects are written to the public-site S3 `live/` prefix.
- CloudFront serves `/live/current.m3u8`, `/live/channels.json`, and per-channel playlists such as `/live/channels/14/current.m3u8`.

AIS:

- AIS-catcher decodes vessel messages on the Pi.
- A local forwarder sends sanitized-bound input to API Gateway over outbound HTTPS.
- Lambda strips private fields and bounds the public payload to local waters.
- Public reads use `/ais/latest.json` and `wss://ais-live.robertboscacci.com/v1`.

Production browsers do not connect directly to the Pi, OptiPlex, LAN Icecast URLs, Tailscale Funnel origins, raw S3 objects, or DynamoDB.

## Processing Path

Clip processing:

- The Pi creates activity clips and sidecar metadata.
- The Pi asks the OptiPlex private API for short-lived presigned upload URLs.
- Raw audio stays in private S3.
- DynamoDB stores clip events, transcripts, corrections, and serving read models.
- The OptiPlex runs `faster-whisper`, review/correction workflows, lexical analysis, and public exports.

Retention and export:

- Unstarred raw `raw/` audio expires after 90 days.
- Starred Hall of Fame clips are tagged for longer retention.
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
