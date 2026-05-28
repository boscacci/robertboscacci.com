---
title: "Laundry Done Detector"
showTableofcontents: true
date: 2026-05-27T00:00:00-07:00
lastmod: 2026-05-28T00:00:00-07:00
draft: false
description: "A washer and dryer vibration sensor that detects when a laundry cycle finishes, sends signed events to a FastAPI relay, and notifies a phone."
summary: "A washer and dryer vibration sensor that detects finished laundry cycles and sends phone notifications."
keywords:
 - Robert Boscacci
 - Software engineering
 - ESP32
 - FastAPI
 - Gotify
 - Home automation
 - Hardware
---

This project uses an ESP32 and accelerometer to detect when a washer or dryer cycle finishes by measuring vibration from the outside of the appliance. It sends a phone notification when the cycle appears to be done.

The source repository is [boscacci/laundry-done](https://github.com/boscacci/laundry-done).

## Components

The hardware side uses:

- ESP32 development board
- I2C accelerometer breakout
- USB power bank or USB power supply
- Small enclosure or sensor puck
- External mounting material, such as tape, strap, magnets, or 3M Dual Lock

The software side uses:

- ESP32 firmware
- FastAPI relay
- SQLite event log
- Gotify for phone notifications
- Browser dashboard for calibration
- Docker Compose for the home-server services

## Sensor Behavior

The ESP32 samples motion from the accelerometer. Each sample window produces values used by the relay and dashboard:

- Vibration strength, representing typical movement during the window
- Biggest jolt, representing the largest instant change in that window

The firmware sends events over Wi-Fi to the relay. Events are signed with an HMAC secret so the relay can reject unsigned traffic.

## Relay Behavior

The FastAPI relay receives ESP32 events, validates the signature, stores event data in SQLite, and forwards finished-cycle alerts to Gotify. The relay also serves a calibration dashboard that shows recent vibration data.

The dashboard is used to compare washer, dryer, quiet, and handling states. This makes it possible to tune thresholds without opening the appliance or changing the firmware for every observation.

## Safety Boundary

The sensor is mounted outside the appliance. It does not open the washer or dryer, modify appliance wiring, touch the dryer outlet, or use mains power inside the enclosure. The ESP32 runs from USB power and observes vibration only.

The enclosure, cable, and power source need to stay clear of doors, hinges, exhaust, moving parts, and hot surfaces.

## Current Outputs

The current system provides:

- Regular ESP32 telemetry while awake
- Signed relay events
- Local event history in SQLite
- Live calibration charts
- Android notifications through Gotify
