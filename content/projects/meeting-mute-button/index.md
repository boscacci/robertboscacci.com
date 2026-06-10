---
title: "Hardware Zoom Mute Button with Arduino and Duct Tape"
showTableofcontents: true
date: 2026-05-27T00:00:00-07:00
lastmod: 2026-06-10T00:00:00-07:00
draft: false
description: "A hardware mute button for Zoom and Microsoft Teams on macOS, using Arduino ESP32 firmware, USB serial messages, and Hammerspoon app control."
summary: "A physical red and green mute button for Zoom and Microsoft Teams on macOS."
featureUrl: "https://media.robertboscacci.com/photos/meeting-mute-button/mute-button-index-simple.png"
featureAlt: "Minimal illustration of a two-button hardware mute controller with red mute and green live buttons."
keywords:
 - Robert Boscacci
 - Software engineering
 - ESP32
 - Hammerspoon
 - Zoom
 - Microsoft Teams
 - Hardware
---

This project is a physical mute button for Zoom and Microsoft Teams on macOS. An ESP32 reads a pushbutton, drives a red/green LED, and reports the desired mute state to the Mac over USB serial.

The source repository is [boscacci/meeting-mute-button](https://github.com/boscacci/meeting-mute-button).

## Components

The hardware side uses:

- ESP32 development board
- Momentary pushbutton
- Common-anode RGB LED using the red and green channels
- LED resistors
- USB cable
- Optional enclosure or project box

The software side uses:

- Arduino ESP32 firmware
- USB serial output
- Hammerspoon on macOS
- macOS Accessibility permission for Teams control

## Hardware Behavior

The firmware reads the button on GPIO0/P0 with the internal pull-up enabled. Pressing the button toggles an internal desired state.

The LED shows that state:

- Red means muted
- Green means unmuted

After each debounced button press, the firmware prints a serial line that includes the new state.

## macOS Behavior

Hammerspoon listens to the ESP32 serial device. When it receives a new desired state, it checks the supported meeting apps and tries to make the active call match the LED state.

The current app priority is:

1. Zoom
2. Microsoft Teams

Zoom is controlled through its Meeting menu. Teams is controlled through the Accessibility tree by finding the in-call microphone button and clicking its center.

## Reliability Handling

The controller treats the ESP32 LED state as the source of truth. It coalesces rapid button presses, waits before trusting stale app UI state, and requires repeated matching observations before treating the app state as settled.

For each LED-state version, Hammerspoon sends at most one app command. If the app does not confirm the requested state, Hammerspoon shows an alert instead of repeatedly toggling the meeting control.

## Current Outputs

The current system provides:

- Hardware mute/unmute state
- Red/green LED indication
- USB serial events
- Zoom mute control
- Microsoft Teams mute control
- Reconnect handling when the ESP32 is unplugged and plugged back in
