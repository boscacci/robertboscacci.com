# How Long?

## AWS deployment

Anyone can open the public HTTPS page and see the current counter. The browser
also checks the private Tailscale Serve endpoint. Only the configured owner's
Tailscale identity can see history, download the CSV or reset the clock. The
public edge removes incoming identity headers. Both paths use the same database
on encrypted EBS and the same S3 timestamp archive.

Enroll the EC2 host once in the owner's tailnet through Systems Manager using
`tailscale up --hostname=howlong-dev --accept-dns=false` (production uses
`howlong-production`). The cloud installer configures private Serve on port
8443. Tailnet clients must be able to reach that port. Browsers that ask for
local network access need permission to discover the owner controls. The
private HTTPS address also serves the page directly.

Build and deploy from the reviewed default branch on the owner-operated release host.

```bash
bash scripts/build-howlong-cloud.sh
bash scripts/deploy-howlong-cloud-dev.sh
```

Verification checks public and owner access without completing a reset. After
enrolling a staged dev host, rerun the dev command with
`HOWLONG_VERIFY_ONLY=1` to finish verification. After the owner smoke-tests dev,
tag the verified commit and record the release tag, commit, digest (artifact),
target hostname, approval instruction and UTC recordedAt for promotion.

```bash
bash scripts/deploy-howlong-cloud-production.sh /path/to/approval.json
```

Both deployments require the existing cloud data volume. The original migration
scripts and procedure are preserved at commit 0667719. Inspect the
howlong-cloud, howlong-cloud-edge, howlong-cloud-tailnet and howlong-cloud-archive
systemd journals through SSM.

## OptiPlex release and rollback

The counter is a separate private service. Its dates and SQLite database live
on OptiPlex. The portfolio build does not include the service, and the service
sends no analytics. It uses Pacific calendar days and starts from the private
`HOWLONG_INITIAL_DATE` setting on first launch. Subsequent starts preserve the
stored date. Keep development and production databases separate.

Tailscale Serve authenticates the request and overwrites browser-supplied
identity headers. It talks to Node through a private Unix socket. Anyone who
can reach the service with a Tailscale user identity may read the counter. Only
the configured owner's identity can confirm a reset. Each click advances a
server-side, single-use confirmation that expires after 30 seconds. The fifth
click updates the date and records one timestamp in the same SQLite transaction.
Only the owner receives the reset totals. All-time totals use the existing counter
revision, so earlier resets still count. The rolling 30-day total uses saved
timestamps and is marked as incomplete if earlier timestamps are unavailable.
The owner's history shows the latest ten recorded resets in Pacific time. Its
CSV download contains every recorded timestamp in UTC with milliseconds and a
reset number. Undated legacy resets appear only in the all-time total.
Open pages refresh about every 10 seconds.

The archive worker copies each dated reset to its environment's private,
encrypted and versioned S3 bucket about once a minute. Each object contains the
reset number and UTC timestamp. SQLite commits the reset before any AWS call.
The worker retries unacknowledged records, checks the S3 checksum, and backfills
existing dated rows. It has scoped, short-lived AWS access to its own archive.

## Development

On OptiPlex, run `npm ci`, `npm run test:howlong` and then run the checked-in
deployment script from a clean reviewed commit. Supply the initial date in the
`HOWLONG_INITIAL_DATE` environment variable in `YYYY-MM-DD` form.

```bash
bash scripts/deploy-howlong.sh dev
bash scripts/deploy-howlong-archive.sh dev
```

The script archives the tracked service, retains the SHA-256 and commit, and
links the user service to that release. It verifies HTTPS and tests that a
browser-supplied identity is overwritten. Tailscale Funnel stays disabled for
the dev endpoint. The deployment record is in `~/.local/share/howlong/dev/dev.json`.
Service logs are available through `journalctl --user -u howlong-dev.service`.

On Tailscale, open the dev URL in two tabs. Check that four clicks show progress
and keep the original date, the fifth click shows zero days, and the other tab
updates. Try five quick taps on a phone. The button and dots should respond
immediately, with a short vibration on devices and browsers that support it.
A non-owner's account should see the count without the reset control.
Confirm that the owner's history increments once on a completed reset, including
a second reset on the same day, and stays hidden for a non-owner.
Check that the latest reset shows a date and time and appears in the CSV download.

## Production

The public address record stays empty. Pi-hole resolves
`howlong.robertboscacci.com` to the OptiPlex Tailscale address. The existing
Tailscale TCP listener and the `rc` front door route the vanity name to a
loopback-only HTTPS edge. The vanity page calls the private Tailscale API so
that the original viewer's identity reaches the counter. The API allows the
one vanity origin for browser requests and still verifies the owner on every
reset step. The TLS role can change only the DNS challenge TXT for this name.

After a human smoke-tests dev, select the exact dev-tested main-branch commit
with an annotated `howlong/vMAJOR.MINOR.PATCH` tag. Record the human's explicit
approval in a private durable release record with `releaseTag`, `artifact`
(the SHA-256 from `dev.json`), `target` (`howlong.robertboscacci.com`),
`instruction` and `recordedAt` (UTC ISO 8601). From clean default branches,
run the following using that one approval. Set `HOWLONG_INITIAL_DATE` to the
desired production starting date on the first command. The dev database is
never copied into production.

```bash
bash scripts/deploy-howlong.sh production /path/to/approval.json
bash scripts/deploy-howlong-archive.sh production
bash scripts/deploy-howlong-edge.sh
# From the rc checkout:
bash optiplex/front-door/activate-howlong.sh
```

The activation verifies the private HTTPS route, a refused LAN connection,
the exact private DNS record and the shared front-door health checks. The
front-door watcher checks the vanity edge and the Tailscale API separately.
Use `journalctl --user -u howlong-production -u howlong-edge -u howlong-edge-renew`
to investigate backend, TLS or certificate credential failures. For release
rollback, retain the database and certificates and promote a prior retained
dev-tested artifact with its annotated tag and approval. Use a SQLite online
backup or stop the service before copying the database for recovery.

The How Long archive sends a heartbeat to CloudWatch in `us-east-1`. A missing
heartbeat alerts the existing `NotifyMe` topic. Inspect archive failures with
`journalctl --user -u howlong-production-archive.service`. The next timer run
retries pending records. For a checksum mismatch, compare the saved SQLite row
with the existing S3 object before retrying. Keep the counter database and
archive together when restoring state so reset numbers are never reused.
