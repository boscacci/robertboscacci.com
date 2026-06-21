---
title: "Global Genetics Professionals Map"
showTableofcontents: true
date: 2026-06-03T00:00:00-07:00
lastmod: 2026-06-21T00:00:00-07:00
draft: false
description: "An authenticated React and Leaflet map for finding genetics professionals worldwide, backed by Google Sheets and GitHub Actions automation."
summary: "An authenticated global directory and map for genetics professionals, with Google Sheets administration and an encrypted static React deployment."
featureUrl: "https://media.robertboscacci.com/photos/genetics-map-app/app-global-map.png"
featureAlt: "Screenshot of the Global Genetics Professionals map interface showing a world map and filter controls."
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

<!-- HANDWRITTEN INTRO START -->

My friend [Monisha Sebastin, MS, CGC](https://www.cham.org/specialties-and-programs/genetics/our-team), who is also on [LinkedIn](https://www.linkedin.com/in/msebastin-ms-cgc), [Google Scholar](https://scholar.google.com/citations?hl=en&user=vQdAXEcAAAAJ), and in this [ABGC spotlight](https://www.abgc.net/Updates/ABGC-Updates/Article/abgc-spotlight-monisha-sebastin-ms-cgc-nsgc-special-projects-award-winner), is a prestigious genetic counselor at the Children's Hospital at Montefiore Einstein in NYC. I was excited when she approached me with an idea for a project that would help connect genetics professionals from around the world.

The ask was for a members-only interactive map web app powered by a growing dataset of survey results submitted by genetics professionals. Genetic counselors, medical geneticists, researchers, et al. submit their names, specialties, languages spoken, institutional affiliations, contact information, and more for presentation on map detail cards. It also needed to be maintainable by a non-programmer, so the app's underlying dataset had to have a friendly GUI interface like Google Sheets.

The system is set up such that the web app can be embedded as part of the broader [Global Genetics Directory](https://www.globalgeneticsdirectory.org/) website, so Monisha can use Squarespace's mass communication and membership administration tools in a nice UI, while the actual map app just works for free on GitHub Pages in the background.

<!-- HANDWRITTEN INTRO END -->

## Screenshots

_Provider names and contact details shown here are example values._

<div class="project-screenshot-gallery">
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-global-map.png" alt="Example desktop screenshot of the genetics professionals app showing a global map, clustered markers, and filter controls.">
    <figcaption>Global map view with clustered provider locations and filters.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-specialty-filtered-map.png" alt="Example desktop screenshot of the genetics professionals app after applying a specialty filter, focused on a Northeast regional map view.">
    <figcaption>Specialty-filtered regional view.</figcaption>
  </figure>
</div>

<div class="project-screenshot-gallery project-screenshot-gallery--mobile">
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-mobile-map.png" alt="Example mobile screenshot of the genetics professionals app with compact filters above the map.">
    <figcaption>Mobile layout.</figcaption>
  </figure>
</div>

<div class="project-screenshot-gallery project-screenshot-gallery--cards">
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-detail-card.png?v=20260621-context" alt="Example provider detail popup for Avery Sample showing role, institution, location, specialty, languages, interpreter services, and a contact button.">
    <figcaption>Provider detail popup.</figcaption>
  </figure>
  <figure>
    <img src="https://media.robertboscacci.com/photos/genetics-map-app/app-contact-card.png?v=20260621-context" alt="Example contact detail modal for Avery Sample showing invented institution, specialty, language, interpreter, email, phone, website, and address fields.">
    <figcaption>Contact detail modal.</figcaption>
  </figure>
</div>

<!-- MACHINE-GENERATED TECHNICAL DRAFT START -->

## Machine-Generated Technical Notes

_Everything below this heading was drafted by OpenAI Codex. These sections are intentionally more structured and bullet-pointed than the introductory copy above._

- **What it is:** a private, key-protected React application for browsing genetics professionals around the world.
- **Core interface:** a full-screen Leaflet map with filters for country, city, language, specialty, and name.
- **Why it exists:** to make a spreadsheet-backed professional directory easier to browse spatially.
- **Source:** [boscacci/genetics-map-app](https://github.com/boscacci/genetics-map-app).
- **Deployed app:** [boscacci.github.io/genetics-map-app](https://boscacci.github.io/genetics-map-app/), with access controlled by a shared URL key.

## What It Does

- Presents genetic counselors and specialists as map markers.
- Supports global browsing, regional zooming, and filtered exploration.
- Filters by country, city, language, specialty, and provider name.
- Recenters the map around matching records when filters are applied.
- Switches the desktop counter from a global total to filtered-result navigation after filtering.
- Handles directory fields including name, job title, institution, website, work location, language, interpreter-services availability, and specialty.
- Supports privacy flags that can hide names, email, phone, institution, and address details from the rendered app.

## Technical Notes

- **Frontend:** React, TypeScript, Leaflet, React Leaflet, marker clustering, React Select, Papa Parse, and CryptoJS.
- **Pipeline:** Google Sheets and Drive APIs, Google geocoding, Python cleaning scripts, Node publishing scripts, GitHub Actions, and GitHub Pages.
- **Hosting model:** static React app deployed through GitHub Pages.
- **Design goal:** keep the admin workflow closer to spreadsheet editing than software deployment.
- **Operational tradeoff:** use automation for fragile data steps, then leave the live map as a cheap static artifact that is simple to host.

## Admin Workflow

- The operational source of truth is a Google Sheet with Working Copy and Production tabs.
- Non-technical administrators edit the Working Copy tab.
- GitHub Actions provides two operational paths:
  - **Promote Only:** stage, geocode, clean, validate, and back up data without publishing the site.
  - **Sync and Deploy:** run the full pipeline and publish the updated static app.
- The publish pipeline:
  - Geocodes new rows.
  - Promotes Working Copy into Production.
  - Cleans and validates records.
  - Writes backups.
  - Encrypts the publishable dataset.
  - Builds the React app.
  - Deploys to GitHub Pages.
- The public static site ships only the encrypted data blob and a hash of the shared access key.

## Privacy Boundary

- The app is static, but provider data is not published as a plain CSV or JSON file.
- A URL key is hashed in the browser to decide whether access is allowed.
- The same key decrypts the embedded AES data blob.
- The page and screenshots deliberately avoid exposing the key or real provider-level details.
- This is not a replacement for a full identity provider or row-level authorization system.
- It is a practical privacy boundary for an invited-audience directory that still benefits from cheap, low-maintenance static hosting.

<!-- MACHINE-GENERATED TECHNICAL DRAFT END -->
