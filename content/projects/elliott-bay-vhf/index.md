---
title: "Elliott Bay Marine VHF Monitor"
showTableofcontents: true
date: 2026-06-17T00:00:00-07:00
lastmod: 2026-10-17T00:00:00-07:00
draft: false
description: "A home-lab marine VHF monitor with SDR capture, browser-playable live audio, AIS, searchable clip transcripts, BERTopic transcript clusters, continuous Whisper Large V3 Turbo transcription, and DockTalk sharing."
summary: "Live Elliott Bay VHF audio, AIS, searchable clips, BERTopic transcript clusters, continuous Whisper Large V3 Turbo transcription, and DockTalk sharing. Built with help from OpenAI Codex."
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

I used OpenAI Codex while building and deploying it. Transcription now runs continuously on the home server with Whisper Large V3 Turbo through faster-whisper. Reviewed corrections and vocabulary hints also feed a separate experimental fine-tuning workflow for maritime radio audio, vessel names, channel jargon, and Seattle Traffic phrasing.

- Production: [seattleboatradio.com](https://seattleboatradio.com/)
- Source: [boscacci/vhf-seattle](https://github.com/boscacci/vhf-seattle)

_Some hardware links below are Amazon affiliate product links. As an Amazon Associate I earn from qualifying purchases._

## Latest Progress

As of October 2026, [Seattle Boat Radio](https://seattleboatradio.com/) has public Listen live controls, continuous transcription, a vessel map, semantic transcript search, topic analysis, and a Performance view for watching the processing backlog.

Eighteen channels are available for individual live listening. The current public release records and transcribes nine of them; the others are live only. The receiver also shares available channels with [DockTalk](https://www.docktalk.app/), alongside the local recording and AIS paths. Thanks to Michael Donovan and the DockTalk community for connecting coastal receivers.

The transcription worker keeps Turbo loaded between clips instead of repeatedly starting the model. It runs locally on the Ubuntu micro-computer, with a reduced CPU ceiling and lower scheduling priority to leave room for other work. A temporary backlog can build during busy periods; the Performance page makes that delay visible.

On dev, the next recording profile adds channels 09, 67, 69, and 72, bringing the total to thirteen. Listening groups cover all available recordings, all but vessel traffic services, or Coast Guard / emergency traffic. Phone playback work keeps the audio session active through quiet periods and adds system media controls. Browser tests cover the phone flows; physical phone lock-screen testing is still needed before promoting that release.

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a [Uniden MHS75 handheld marine radio](https://www.amazon.com/dp/B001J5MQ20?tag=robertboscacc-20). Instead, I decided it would be more useful and more interesting to connect an [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20) to a [Raspberry Pi 4 starter kit](https://www.amazon.com/dp/B07V5JTMV9?tag=robertboscacc-20) and do computer-based processing with the audio.

## Screenshots

These earlier screenshots show the clips, live monitoring, transcript search, word/entity analysis, and BERTopic views. The current app also includes the newer listening controls and Performance view described above.

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

The public site reads through AWS. Static assets and public exports use private S3 origins; approved live MP3 routes pass through CloudFront to a read-only proxy on the home processing path. Browsers do not connect directly to the Pi, LAN Icecast URLs, private raw audio, or DynamoDB. Write-capable operator tools stay on the private/dev path over the tailnet.

SQLite is retained only for explicit legacy backfills, local fixtures, and separate realtime telemetry.

![Production boundary diagram for Elliott Bay VHF](https://media.robertboscacci.com/photos/elliott-bay-vhf/production-boundary.png)

_Earlier architecture diagram; current live MP3 delivery uses the read-only proxy described above._

## Radio And Live Paths

Radio capture:

- A [Bingfu VHF/UHF antenna kit](https://www.amazon.com/dp/B0CLKLHHNP?tag=robertboscacc-20), an [RTL-SDR Blog V4 receiver](https://www.amazon.com/dp/B0CD745394?tag=robertboscacc-20), and a dAISy-catcher receiver feed the Raspberry Pi.
- RTLSDR-Airband provides eighteen live marine VHF channels, with a smaller recording profile to bound transcription load. Channel 74 is excluded.
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
- The public map uses local AIS receiver data, with a same-origin `/ais/latest.json` snapshot and an optional API Gateway WebSocket path.

## Processing Path

Clip processing:

- The Pi creates activity clips and sidecar metadata, then asks the private API for short-lived upload URLs.
- Raw audio stays in private S3.
- DynamoDB stores clip events, transcripts, corrections, and serving read models.
- The Ubuntu micro-computer runs continuous Whisper Large V3 Turbo through `faster-whisper`, review/correction workflows, transcript analysis, and public exports.
- Automatic audio and transcription quality checks quarantine clearly poor or unintelligible clips from the default feed while retaining them for private review. Accepted clips keep the full playable audio in the transcription path.

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
