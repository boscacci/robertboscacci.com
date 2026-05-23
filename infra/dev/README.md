# Development Hosting

This OpenTofu stack provisions a separate public development environment for
`robertboscacci.com`:

- `dev.robertboscacci.com` Route53 `A` and `AAAA` alias records
- ACM certificate in `us-east-1`, validated through Route53
- Private S3 bucket for the rendered Hugo artifact
- CloudFront distribution with Origin Access Control
- `X-Robots-Tag: noindex, nofollow, noarchive` response header
- IAM role for GitHub Actions OIDC development deploys

Production remains on the existing GitHub Pages flow for `robertboscacci.com`.

## Apply

```bash
cd infra/dev
tofu init
tofu plan
tofu apply
```

The current development deploy values are checked into `.github/workflows/dev-preview.yml`
because they are resource identifiers, not secrets:

- `AWS_REGION=us-west-2`
- `AWS_ROLE_TO_ASSUME=arn:aws:iam::062008221187:role/robertboscacci-com-dev-github-actions`
- `DEV_S3_BUCKET=robertboscacci-com-dev-site`
- `DEV_CLOUDFRONT_DISTRIBUTION_ID=E282I2XU6PLMW4`

The stack creates `AWS_ROLE_TO_ASSUME` with a GitHub Actions OIDC trust policy
scoped to this repository's `development` environment and `develop` branch.
