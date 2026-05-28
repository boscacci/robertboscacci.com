# Media Hosting

This OpenTofu stack provisions versioned S3-backed media hosting for
`robertboscacci.com`:

- `media.robertboscacci.com` Route53 `A` and `AAAA` alias records
- ACM certificate in `us-east-1`, validated through Route53
- Private S3 bucket with versioning enabled
- CloudFront distribution with Origin Access Control
- Server-side encryption and public-access blocking on the bucket

The bucket stores source photo files outside git. CloudFront serves public URLs
for Hugo posts.

## Apply

```bash
cd infra/media
tofu init
tofu plan
tofu apply
```

After apply, copy the `site_media_env` output values into
`config/site-media.env`.
