---
title: "Global Genetics Professionals Map"
showTableofcontents: true
date: 2026-06-21T00:00:00-07:00
lastmod: 2026-06-21T00:00:00-07:00
draft: false
description: "An authenticated React and Leaflet map for finding genetics professionals worldwide, backed by Google Sheets and GitHub Actions automation."
summary: "An authenticated global directory and map for genetics professionals, with Google Sheets administration and an encrypted static React deployment."
featureUrl: "https://media.robertboscacci.com/photos/genetics-map-app/app-global-map.png"
featureAlt: "Synthetic screenshot of the Global Genetics Professionals map interface showing a world map and filter controls."
keywords:
 - Robert Boscacci
 - Software engineering
 - React
 - TypeScript
 - Leaflet
 - Google Sheets
 - GitHub Actions
 - Genetics
 - Privacy
---

<!-- HUMAN COPY INSERTION POINT: Add Robert's first-person intro above or below this comment. -->
<!-- MACHINE-GENERATED TECHNICAL DRAFT START -->

The Global Genetics Professionals map is a private, key-protected React application for browsing genetics professionals around the world. It combines a full-screen Leaflet map with filters for country, city, language, specialty, and name, so administrators and invited users can explore a directory spatially instead of searching through a spreadsheet.

The source repository is [boscacci/genetics-map-app](https://github.com/boscacci/genetics-map-app). The deployed app lives at [boscacci.github.io/genetics-map-app](https://boscacci.github.io/genetics-map-app/), but access requires a shared key in the URL.

## Screenshots

These screenshots use synthetic demo records rendered through the app interface. They show the UI and workflow without exposing real provider names, contact information, addresses, or the access key.

<div class="project-screenshot-gallery">
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-global-map.png" alt="Synthetic desktop screenshot of the genetics professionals app showing a global map, clustered markers, and filter controls.">
    <figcaption>Global map view with clustered provider locations and filters.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-filtered-map.png" alt="Synthetic desktop screenshot of the genetics professionals app after applying a country filter.">
    <figcaption>Filtered view focused on one region.</figcaption>
  </figure>
</div>

<div class="project-screenshot-gallery project-screenshot-gallery--mobile">
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-mobile-map.png" alt="Synthetic mobile screenshot of the genetics professionals app with compact filters above the map.">
    <figcaption>Mobile layout.</figcaption>
  </figure>
</div>

## What It Does

The app presents genetic counselors and specialists as map markers. Users can browse globally, zoom into regions, and narrow the list with filter controls. When filters are applied, the map recenters around the matching records and the desktop counter switches from a global total to filtered-result navigation.

The directory fields include provider name, job title, institution, website, work location, language, interpreter-services availability, and specialty. Privacy flags can hide names, email, phone, institution, and address details from the rendered app.

## Admin Workflow

The operational source of truth is a Google Sheet with Working Copy and Production tabs. Non-technical administrators edit the Working Copy tab, then run either a staging workflow or a publish workflow in GitHub Actions.

The pipeline geocodes new rows, promotes Working Copy into Production, cleans and validates records, writes backups, encrypts the publishable dataset, builds the React app, and deploys it to GitHub Pages. The public static site ships only the encrypted data blob and a hash of the shared access key.

## Privacy Boundary

The app is static, but the provider data is not published as a plain CSV or JSON file. A key from the URL is hashed in the browser to decide whether access is allowed, then the same key decrypts the embedded AES data blob. The page and screenshots here deliberately avoid exposing the key or real provider-level details.

This is not a replacement for a full identity provider or row-level authorization system. It is a practical privacy boundary for an invited-audience directory that still benefits from cheap, low-maintenance static hosting.

## Technical Notes

The frontend is built with React, TypeScript, Leaflet, React Leaflet, marker clustering, React Select, Papa Parse, and CryptoJS. The data pipeline uses Google Sheets and Drive APIs, Google geocoding, Python cleaning scripts, Node publishing scripts, GitHub Actions, and GitHub Pages.

The design goal was to keep the admin workflow closer to spreadsheet editing than software deployment: maintain the directory in a familiar interface, use automation for the fragile steps, and leave the live map as a static artifact that is simple to host.

<!-- MACHINE-GENERATED TECHNICAL DRAFT END -->
