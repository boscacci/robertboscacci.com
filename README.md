# robertboscacci.com

Personal portfolio site built with [Hugo](https://gohugo.io/) and the [Congo](https://github.com/jpanther/congo) theme. Production deploys to GitHub Pages from a GitHub Actions artifact built on `main`.

## Local development

```bash
git submodule update --init --recursive
hugo server --disableFastRender
```

For a production-equivalent build:

```bash
hugo --gc --minify --cleanDestinationDir --environment production --baseURL "https://robertboscacci.com/"
```

For a development-subdomain build:

```bash
hugo --gc --minify --cleanDestinationDir --environment development --baseURL "https://dev.robertboscacci.com/"
```

## Media workflow

Post photos are kept out of git and synced to versioned S3-backed media hosting.
See [docs/media-workflow.md](docs/media-workflow.md) for the drop-folder,
LaunchAgent, and external-image migration workflow.

## Environments

Production deploys to GitHub Pages from `main` using `.github/workflows/gh-pages.yml` and the `robertboscacci.com` custom domain in `static/CNAME`. The repository Pages source should be configured as `build_type=workflow`, not the legacy `gh-pages` branch source.

Development is designed as a separate AWS-hosted static site at `dev.robertboscacci.com`. The repo-side deployment workflow is `.github/workflows/dev-preview.yml`; the AWS/Route53/CloudFront/S3 resources are described in `infra/dev/`. Development builds set noindex robots metadata and the CloudFront stack adds an `X-Robots-Tag` noindex response header.

The GitHub Actions workflows currently pin Hugo `0.163.2`.

## Deploy a feature branch to dev

Keep dev-only changes on a short-lived feature branch: pushing `main` currently
publishes production automatically. Do not merge a dev preview into `main` until
production publication is requested.

Install Node dependencies with `npm ci` and the browser with
`npx playwright install chromium`. Use Hugo `0.163.2`, matching the workflows.
From a clean committed checkout with AWS access to the existing development
bucket and distribution, run:

```bash
HUGO_BIN=/path/to/hugo scripts/deploy_dev.sh
```

The script verifies the AWS account and dev origin, builds an immutable archive
identified by the exact commit, runs Playwright against that artifact, syncs it
to dev, invalidates CloudFront, then checks the deployed pages and commit marker.
Structured lifecycle messages and failures go to the terminal. Archives, SHA-256
checksums and successful deployment receipts stay in ignored
`outputs/dev-releases/<commit>/`; retries reuse and verify the same archive.
Temporary extraction/build directories are removed on success or failure.
Retain archives for rollback: redeploy the earlier reviewed commit with its
existing archive through the same script. A failed post-deploy smoke exits
nonzero and leaves the archive available for diagnosis and rollback.

The browser suite checks navigation to the three hardware/radio projects,
updated content, dev noindex metadata, and mobile/desktop overflow:

```bash
SITE_DIRECTORY=public npm test   # an existing development build
npm run smoke:dev               # the deployed development site
```
