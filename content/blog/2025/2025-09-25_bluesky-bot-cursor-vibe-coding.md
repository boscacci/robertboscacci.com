---
title: "Bluesky Bot with Cursor IDE and Vibe-Coding"
toc: false
date: 2025-09-25T02:25:46-05:00
lastmod: 2025-09-25T02:25:46-05:00
draft: false
Description: "Robert Boscacci built a multi-modal GPT-4o Bluesky bot with computer vision that was so convincing he had to shut it down. Built with Cursor IDE." # Keep to 150-160 chars
Summary: "Building and shutting down an AI bot that was indistinguishable from human users"
keywords:
 - Robert Boscacci
 - Data science
 - AI
 - Bluesky
 - Bot Development
 - Cursor IDE
 - Computer Vision
 - GPT-4o
 - Multi-modal AI
 - Python
 - Flask
---

## The Project

Monday-Tuesday, I build and deploy a computer vision ("AI") powered Bluesky bot, along with a web control panel. Today I shut it down, because I'm told its replies are indistinguishable from a human user—which is annoying people. To be clear: I never type any replies myself. I just push a button, and the bot (powered by GPT-4o) generates and posts all the responses automatically.

<a href="https://images.squidge.org/images/2025/09/25/bsky_reply_guy.jpeg" target="_blank" rel="noopener">
  <img src="https://images.squidge.org/images/2025/09/25/bsky_reply_guy.jpeg" alt="Screenshot of Bluesky bot reply" width="800"/>
</a>

The bot uses a multi-modal OpenAI model (4o) to analyze image posts and generate replies based on the actual image content. I give it a "personality" (Seattle-based cyclist) and infuse it with my own "values" (accessible urban infrastructure advocacy) via prompt engineering. I am impressed when it reads the slogan off a lady's shirt in a photo and works that into a comedic reply—all without any manual input from me.

The idea is to spur conversation around topics I genuinely care about.

**GitHub Repository**: [bluesky-image-reply-bot](https://github.com/boscacci/bluesky-image-reply-bot)

## The Reality Check

Ultimately, another user reads the profile description (explicitly says "bot account") and tells me what I need to hear: He doesn't like it one bit. Social media platforms like Bluesky don't need more AI slop.

Honestly, I know this in my heart of hearts. Nobody wants headless bots leaving dad jokes all over their feed, thematically relevant or not.

## The Learning Experience

That said, I have great fun learning and experimenting with:

- Agentic programming in the Cursor IDE
- The OpenAI API + sending it hybrid text-image prompts
- Bluesky's API (and the AT protocol)
- Python/Flask (for the API and GUI)

## Moving Forward

These are powerful tools, so I want my next project to be more genuinely useful to real folks in my actual community. Well, what I really want is a job leveraging these sorts of tools. But you'll see me doing these hackathon-y portfolio projects until then!
