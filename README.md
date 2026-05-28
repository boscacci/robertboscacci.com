# robertboscacci.com

Personal portfolio site built with [Hugo](https://gohugo.io/) and the [Congo](https://github.com/jpanther/congo) theme. Production deploys to GitHub Pages from `main`.

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

Production deploys to GitHub Pages from `main` using `.github/workflows/gh-pages.yml` and the `robertboscacci.com` custom domain in `static/CNAME`.

Development is designed as a separate AWS-hosted static site at `dev.robertboscacci.com`. The repo-side deployment workflow is `.github/workflows/dev-preview.yml`; the AWS/Route53/CloudFront/S3 resources are described in `infra/dev/`. Development builds set noindex robots metadata and the CloudFront stack adds an `X-Robots-Tag` noindex response header.

The GitHub Actions workflows currently pin Hugo `0.162.0`.
