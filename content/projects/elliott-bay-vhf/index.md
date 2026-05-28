---
title: "VHF Chatter in Elliott Bay"
showTableofcontents: true
date: 2026-05-27T17:45:00-07:00
lastmod: 2026-05-28T00:00:00-07:00
draft: false
description: "A home-lab marine VHF listening project with Raspberry Pi capture, a used Dell OptiPlex Ubuntu server, live audio, clips, and transcripts."
summary: "Live Elliott Bay marine VHF capture with recent clips, transcripts, and language analysis."
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

This project captures selected Elliott Bay marine VHF radio traffic and publishes a read-only web interface with live audio, recent clips, transcripts, and language analysis. The production site is [vhf.robertboscacci.com](https://vhf.robertboscacci.com/), with a separate development site at [vhf-dev.robertboscacci.com](https://vhf-dev.robertboscacci.com/).

## Why

I learned about the marine radio channels while taking the online classes for the Washington boater safety card. I now see a wide variety of boats going by on Elliott Bay, so I wanted to know what they say to each other.

I originally considered buying a handheld marine radio. Instead, I decided it would be more useful and more interesting to connect a receiver to a Raspberry Pi and do computer-based processing with the audio.

## Current Shape

The system has three runtime layers:

- Raspberry Pi radio edge near the antenna and RTL-SDR receiver
- Used Dell OptiPlex desktop repurposed as a small Ubuntu home server on the local network
- AWS public edge using private S3 origins, CloudFront, ACM, and Route 53

The Raspberry Pi handles the radio work that needs to be near the antenna: VHF capture, live MP3 output, activity detection, bounded local clip spooling, and short rolling buffers. The OptiPlex is a secondhand office desktop originally bought as a Windows box and repurposed with Ubuntu; in this project it handles the private API, SQLite metadata, transcription workers, export jobs, and the read-only live proxy. AWS hosts the private static-site origins, raw-audio buckets, CloudFront distributions, certificates, DNS records, and public read-only delivery paths.

## Radio Path

The normal path is:

- Antenna to RTL-SDR receiver
- RTL-SDR receiver to Raspberry Pi
- Raspberry Pi to the OptiPlex Ubuntu server over the private LAN
- OptiPlex Ubuntu server to private S3 and CloudFront
- CloudFront to the public browser

The public monitored channel list currently includes:

- VHF 13 at 156.650 MHz, bridge-to-bridge traffic
- VHF 14 at 156.700 MHz, Seattle Traffic / Puget Sound VTS

The repo also keeps metadata for other nearby marine VHF channels, including VHF 68. The default live behavior remains centered on VHF 14, while the multichannel public profile exposes VHF 13 and VHF 14 channel paths.

## Processing Path

The Pi can stream live audio, detect activity, and create clip sidecar metadata without holding long-lived AWS credentials. Durable uploads go through the private API using short-lived presigned S3 URLs.

The OptiPlex Ubuntu server records clip metadata in SQLite, runs transcription, generates public exports, and serves the read-only live origin used by CloudFront. The public export copies safe audio files, removes private fields, skips very short or nearly silent clips, and preserves the language-analysis artifacts used by the public app.

## Public Boundary

The public site exposes static app assets, live audio/status, recent public clips, transcript text, and language-analysis data. It does not expose radio controls, ingest endpoints, raw S3 object keys, presigned URLs, private database access, long-lived credentials, LAN Icecast URLs, or the Raspberry Pi's local services.

The project keeps development and production deployments separate. The development site is used for smoke tests and UI changes before promotion to production.

## Infrastructure

Infrastructure is managed with OpenTofu. The AWS layer uses separate dev and production static-site buckets, separate raw-audio buckets, CloudFront Origin Access Control, TLS certificates, DNS records, and server IAM policies. Raw audio in the `raw/` prefix is private and expires by lifecycle rule; published app assets and public clip audio are separate outputs.

## Current Outputs

The current public interface includes:

- Live audio playback
- Recent clips
- Transcript text where available
- Channel status and channel-specific live paths
- Language-analysis JSON and topic-cluster output
- A development site for validating UI and analysis changes before production promotion
