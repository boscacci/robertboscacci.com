# Family trips hub

The standalone trips site is separate from the Hugo portfolio. Both environments
have public CloudFront/S3 delivery of encrypted individual documents and private
OptiPlex delivery of the index plus automatically opened documents:

| Environment | Host | Private TLS / health ports |
| --- | --- | --- |
| dev | trips-dev.robertboscacci.com | 9451 / 19451, loopback only |
| production | trips.robertboscacci.com | 9450 / 19450, loopback only |

The public root and non-trip routes return 404. CloudFront can read only the
bucket's `public/` prefix, not retained release archives. S3 has no public access.
Public documents are encrypted with the existing family password held in SSM.
Neither a password nor plaintext itinerary is committed or put in a container.
No public index, sitemap, analytics, or remembered password is provided.

Pi-hole supplies interface-localized LAN and tailnet answers. The public DNS
records point to CloudFront. The rc repository owns the shared nginx SNI routing
and exact private DNS changes. Existing tailnet DNS points to OptiPlex; no global
resolver change, new Funnel route, WAN forwarding, or second port-443 listener
is needed. Trust is enforced before HTTP proxying: only home LAN and loopback
(the existing authenticated Tailscale TCP entrance) can select the trip backend.
HTTP identity and forwarding headers never grant access. Home devices using
external DNS get the public password-protected view until they use home DNS or
Tailscale. The index remains unavailable publicly even if the password is known.

## Editing and immutable builds

Each encrypted document in `services/trips/pages/` embeds private JSON metadata:
`slug`, `title`, `dates`, `status`, and `summary`. These fields are read only after
decryption. Slugs are canonical lowercase hyphen-separated names. The private
index escapes metadata and derives its cards from the decrypted release.

Use `decryptPage` and `readPassword` from the existing private-trip module to
recover a document into ignored `data/private-trips/`, edit there, then use
`encryptPage` to replace its encrypted file. Keep the planner's professional,
prospective voice. Published posts are reference snapshots; the separately
linked private Google Sheet holds editable checklist status and does not sync.
Do not add passport numbers, medical records, payment details, or secrets.
Delete working plaintext after verifying the encrypted replacement.

From a clean reviewed commit:

```bash
npm ci
npm test
npm run test:hub
# Only when the container's Dockerfile/Caddyfile changes:
bash scripts/build-trips-image.sh
node scripts/trips-release.mjs build
node scripts/trips-release.mjs deploy dev
```

The image builder uses pinned Caddy and Route53 plugin versions, publishes an
immutable commit tag to this account's ECR registry, waits for scanning, and
blocks high/critical findings. The unneeded curl/Brotli packages are removed from
the runtime. Runtime is non-root, read-only, loopback-bound, and drops capabilities.
Builds use an isolated builder and temporary tmpfs Docker credentials; cleanup
removes only that builder and its cache. At least 30 GiB free disk is required.
Inspect shared-host cache usage first and keep unused cache below 10 GiB.

The release builder tests the commit and produces a normalized archive containing
encrypted pages, public files, a commit/image manifest, and file hashes. The
deploy script extracts that same SHA-256-verified archive, publishes its public
files, retains the archive privately in S3, starts the private view, activates
the reviewed rc routing/DNS scripts, and runs Playwright on all three entrances.
Dev delivery has no human approval gate. A verified record is retained with the
artifact in S3, with its commit, image digest, artifact hash and environment.

## Host recovery and credentials

The host release record and encrypted archive live under `~/.local/share/trips`.
Plaintext is generated only under the user's tmpfs runtime directory. Certificate
storage persists in private runtime state, outside Git. The user systemd service
refreshes every 15 minutes and after boot, reconstructing private content and
refreshing one-hour STS credentials. The container receives only the temporary
Route53 role credentials, not the host's AWS directory or the family password.
The role can change TXT records only for the two ACME challenge names.

```bash
systemctl --user status trips-refresh.timer
systemctl --user start trips-refresh.service
journalctl --user -u trips-refresh.service -n 20
docker inspect trips-dev-private --format '{{.State.Health.Status}}'
node tests/trips/browser.mjs dev
```

Health endpoints contain no trip data. Existing rc front-door checks cover TLS
and core shared services; dev activation installs conditional trips checks. A
failed refresh logs an actionable event without secrets and retries on the
timer. Never enable password traces or log AWS response credentials. The public
encrypted view is independent of home power; automatic opening and the index
depend on OptiPlex, home networking and the tailnet. Stale private DNS caches can
briefly outlive a network change. A raw hostname/IP is not an authorization token.

## Infrastructure and production

`scripts/provision-trips.sh --apply` operates from a clean reviewed commit and
manages only the dedicated trips resources in AWS account 062008221187. The
bootstrap script idempotently configures encrypted, versioned, non-public remote
state in `robertboscacci-com-state-062008221187`; resource state uses the
`trips/opentofu.tfstate` key and S3 native locking. State never enters Git.
Both hostnames and empty production hosting may be provisioned before content
approval; production trip content and private overrides must remain unpublished.

After the human manually smoke-tests dev, record exactly one approval identifying
the release tag, artifact SHA-256, and `trips.robertboscacci.com` target in a durable
release record. Tag the exact accepted default-branch commit with an annotated,
unused `trips/vMAJOR.MINOR.PATCH`; the tag alone is not approval. The approval JSON
has `releaseTag`, `artifact`, `target`, `approvedBy`, and `approvalUrl` pointing
to the recorded human approval. Do not merge PR #2 before the approval because
the pre-existing portfolio main workflow automatically publishes its legacy page.

```bash
node scripts/trips-release.mjs deploy production /path/to/approval.json
```

Production requires the tag/commit match, the approval record, and the dev
verification for the exact archive. It promotes the archive and image by digest;
it never reruns encryption or rebuilds the image. Rollback selects a retained,
dev-verified release and follows that same single approval process. Keep the
previous encrypted release and certificate volumes. Restoring old ciphertext
requires its matching password; historical downloaded ciphertext cannot be revoked.
