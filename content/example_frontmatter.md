---
title: "Example Page"
date: 2024-01-20T02:25:46-05:00
lastmod: 2024-01-20T05:25:46-05:00
draft: false
slug: "template"
description: "Robert Boscacci is a data scientist reading books on startups and micro-saas"
summary: "Short summary for blog listing."
keywords:
 - Robert Boscacci
 - NYC
 - Entrepreneur
 - Startups
 - Indie Hackers
 - SEM
 - Bootstrapping
weight: 0
---

**Blog Post File Structure:**  
Use: `content/blog/YEAR/filename.md`  
Avoid: `_index.md` files for posts.

**Required frontmatter:**  
- `title`
- `date` (ISO format)
- `slug`
- `summary`
- `draft: false`

**Recommended:**  
- `description` (SEO, 150-160 chars)
- `keywords`
- `lastmod`

---

{{< lead >}}When life gives you lemons, make lemonade.{{< /lead >}}

{{< alert "email" >}}[Subscribe](https://twitter.com/jpanther) for updates on my $500 MRR journey!{{< /alert >}}

{{< figure src="https://images.unsplash.com/photo-1688890968318-8d77993d3b99?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D" alt="Abstract purple artwork" caption="Photo by [Jr Korpa](https://unsplash.com/@jrkorpa) on Unsplash" >}}

{{< button href="#button" target="_self" >}}Call to action{{< /button >}}

---

**Troubleshooting:**  
- Use `.md` (not `_index.md`) for posts  
- `date:` must be ISO format  
- Add `summary:` for concise blog listing  
- Always set `slug:`  
- Use simple directory structure
