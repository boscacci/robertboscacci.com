# Site Media Drop Folder

Put local photo files for `robertboscacci.com` here, grouped by post slug:

```text
data/site-media/
├── elliott-bay-vhf/
├── laundry-done/
└── meeting-mute-button/
```

Files in these folders are intentionally ignored by git. Sync them to the S3
media bucket with:

```bash
scripts/sync_site_media.sh --print-urls
```

Use web-safe filenames with lowercase letters, numbers, hyphens, underscores,
and normal image extensions.
