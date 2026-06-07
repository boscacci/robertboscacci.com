---
title: "Elliott Bay Marine VHF Monitor"
showTableofcontents: true
date: 2026-05-27T17:45:00-07:00
lastmod: 2026-06-06T17:46:09-07:00
draft: false
description: "A Codex-built marine VHF monitoring system with SDR capture, live HLS audio, AIS, transcript search, channel analysis, and a Whisper fine-tuning loop for maritime radio."
summary: "Live Elliott Bay VHF audio, AIS, searchable clips, channel analysis, and Whisper fine-tuning for maritime radio, built with OpenAI Codex."
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

This is a home-lab marine-radio station for Elliott Bay: Raspberry Pi SDR receivers capture live VHF and AIS, an OptiPlex processes clips and transcripts, and AWS serves live HLS audio, vessel positions, searchable clips, Hall of Fame audio, and channel analysis.

I built it with OpenAI Codex as the day-to-day coding partner. The most interesting part is the feedback loop: maritime radio clips are transcribed with Whisper, reviewed and corrected in the operator UI, then fed into a fine-tuning pipeline so the model gets better at vessel names, channel jargon, Seattle Traffic phrasing, and scratchy VHF audio.

- Production: [vhf.robertboscacci.com](https://vhf.robertboscacci.com/)
- Development: [vhf-dev.robertboscacci.com](https://vhf-dev.robertboscacci.com/)
- Source: [boscacci/vhf-seattle](https://github.com/boscacci/vhf-seattle)

_Some hardware links below are Amazon affiliate product links. As an Amazon Associate I earn from qualifying purchases._

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a [Uniden MHS75 handheld marine radio](https://www.amazon.com/dp/B001J5MQ20?tag=robertboscacc-20). Instead, I decided it would be more useful and more interesting to connect an [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20) to a [Raspberry Pi 4 starter kit](https://www.amazon.com/dp/B07V5JTMV9?tag=robertboscacc-20) and do computer-based processing with the audio.

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
    <img src="https://media.robertboscacci.com/photos/elliott-bay-vhf/app-analysis-channel-bars.png" alt="Analysis dashboard bar chart of analyzed transcript clips by VHF channel for Elliott Bay VHF">
    <figcaption>Analysis.</figcaption>
  </figure>
</div>

![Transcript topic cluster animation for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/topic-clusters.gif)

_Transcript topic cluster view._

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

## Architecture

The system has three runtime layers:

- **Raspberry Pi radio edge** ([Raspberry Pi 4 starter kit](https://www.amazon.com/dp/B07V5JTMV9?tag=robertboscacc-20)): VHF voice capture, AIS decode, HLS segment generation, activity detection, clip spooling, and bounded local buffers.
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

- A [Bingfu VHF/UHF antenna kit](https://www.amazon.com/dp/B0CLKLHHNP?tag=robertboscacc-20) and [RTL-SDR Blog V4 receivers](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20) feed the Raspberry Pi.
- RTLSDR-Airband monitors a 12-channel marine VHF profile: 05A, 06, 09, 13, 14, 16, 22A, 67, 68, 69, 71, and 72.
- VHF 14 remains the default live feed for Seattle Traffic / Puget Sound VTS.
- A second [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20) runs AIS-catcher around 162 MHz.

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
