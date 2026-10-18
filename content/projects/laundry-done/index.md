---
title: "Laundry Done Detector"
showTableofcontents: true
date: 2026-05-27T00:00:00-07:00
lastmod: 2026-10-17T00:00:00-07:00
draft: false
description: "A washer and dryer vibration sensor that detects when a laundry cycle finishes, sends signed events to a FastAPI relay, and notifies a phone."
summary: "An ESP32 laundry sensor with observed-motion completion checks, phone notifications, and encrypted Wi-Fi firmware updates."
featureUrl: "https://media.robertboscacci.com/photos/laundry-done/laundry-done-index.png"
featureAlt: "Illustration of a washer and dryer vibration sensor with a phone notification."
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

## Latest Progress

The detector has moved from basic vibration reporting toward a more careful completion decision. The relay now needs at least eight minutes of observed activity followed by four minutes of observed quiet, with smoothing also confirming quiet, before sending a completion notification.

Missing packets are not quiet readings. A reboot, uptime reset, or reporting gap longer than three minutes resets the current monitoring session. Extreme jolts are excluded before smoothing so that handling the sensor cannot leave a trail of false activity in later readings. Measured desk-noise, mounted-idle, dryer-finishing, and delicates-cycle fixtures now exercise these cases in regression tests.

The notification says “Laundry stack stopped.” One accelerometer on a shared frame cannot reliably identify which appliance is running, and gentle washer motion still needs more validation. The firmware controls sampling and power; the relay owns completion alerts.

Firmware can now receive authenticated, encrypted updates over Wi-Fi after an initial USB flash. The update is offered through the normal signed telemetry response, and installation is confirmed by signed post-reboot telemetry matching the expected image hash. Routine updates wait until the device is idle or done and should be staged between loads.

Battery-bank behavior remains a hardware experiment. Startup settling, bounded waiting for a load to begin, sleep intervals, and keepalive behavior have been revised. An emergency recovery image was verified installed in September, but that proves installation and initial operation; complete-cycle battery retention and actual energy savings still need measurement.

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

The FastAPI relay receives ESP32 events, validates the signature, stores event data in SQLite, and infers finished-cycle alerts for Gotify from observed motion and quiet in the current device session. The relay also serves a calibration dashboard that shows recent vibration data.

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
