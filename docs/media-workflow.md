# S3 Media Workflow

Photos for `robertboscacci.com` should live outside git and sync to the shared
S3 media bucket. The source bucket has S3 versioning enabled so overwrites and
deletes remain recoverable in AWS.

## One-Time Setup

1. Apply the media infrastructure:

   ```bash
   cd infra/media
   tofu init
   tofu plan
   tofu apply
   ```

2. Copy the `site_media_env` output values into `config/site-media.env`:

   ```bash
   cp config/site-media.env.example config/site-media.env
   ```

3. Install the optional macOS LaunchAgent:

   ```bash
   scripts/install_site_media_watcher.sh
   ```

The LaunchAgent runs the sync script every five minutes. Logs go to
`~/Library/Logs/robertboscacci-site-media-sync.log` and
`~/Library/Logs/robertboscacci-site-media-sync.err.log`.

## Daily Use

Drop files into `data/site-media/<post-slug>/`:

```text
data/site-media/
├── elliott-bay-vhf/
├── laundry-done/
└── meeting-mute-button/
```

Then either wait for the LaunchAgent or run:

```bash
scripts/sync_site_media.sh --print-urls
```

The default public URL shape is:

```text
https://media.robertboscacci.com/photos/<post-slug>/<filename>
```

Use lowercase, web-safe filenames with hyphens or underscores. Avoid spaces and
camera-original filenames when the image will be linked from a post.

## Migrating Existing External Images

To download a local copy of externally hosted images currently referenced by the
site:

```bash
scripts/download_external_media.sh
scripts/sync_site_media.sh --print-urls
```

The download script writes `outputs/external-media-map.tsv` with:

```text
original_url    new_url    local_path
```

Use that map to update content deliberately. The script does not rewrite posts
automatically.

## Manual Checks

Dry-run the upload:

```bash
scripts/sync_site_media.sh --dry-run --print-urls
```

Check bucket versioning:

```bash
aws s3api get-bucket-versioning --bucket robertboscacci-com-media
```

List uploaded files:

```bash
aws s3 ls s3://robertboscacci-com-media/photos/ --recursive
```
