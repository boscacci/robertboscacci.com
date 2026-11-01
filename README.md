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

## Google Analytics

The public GA4 measurement ID is configured once in
`config/_default/config.toml` under `[services.googleAnalytics]`. The shared
`layouts/_partials/head.html` calls Congo's analytics partial, so production
Hugo pages (including articles, lists, pagination and 404) receive one Google
tag. Development previews disable analytics to avoid polluting production data.
Static encrypted private pages bypass Hugo's templates and remain untracked.

An independently verified copy of the ID is stored in AWS Secrets Manager as
`robertboscacci.com/google-analytics/measurement-id`, in `us-west-2`, account
`062008221187`. This is a public browser identifier, not an account credential;
the checked-in Hugo configuration makes ordinary builds independent of AWS
credentials. When changing the ID, update the secret, Hugo configuration, and
expected public ID in `tests/analytics.test.mjs` together. Never store Google
account credentials in these files.

`npm run test:analytics` builds production and development in temporary folders,
checks every rendered HTML page, and uses Playwright to verify initialization
while blocking external requests. The required PR validation runs this test.

From a clean reviewed commit, `npm run deploy:site:dev` validates, creates an
immutable archive under ignored `outputs/site-releases/<commit>/`, uploads to the
verified development bucket, invalidates CloudFront, and runs Playwright against
dev. It preserves private pages and performs no bucket deletions. It verifies
uploaded checksums and records the artifact hash and dev result. Failed attempts
remove their unverified artifact directory; successful artifacts remain for review.
Production still uses the existing GitHub Pages workflow; merging into `main`
publishes production, so hold the PR until the required human dev smoke test and
explicit production release approval.

Private encrypted reference pages use the workflow in [docs/private-trip.md](docs/private-trip.md).
