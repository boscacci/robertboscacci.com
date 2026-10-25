# Private trip page

The family trip reference page is a standalone StatiCrypt 3.5.4 encrypted HTML
artifact under `static/private/family-2027/index.html`. Hugo copies it unchanged.
There are no site navigation links, feeds, search entries, analytics, remote
assets, or plaintext trip content in the public repository. The route is public;
the content is protected by encryption, not by the obscurity of its address.
Robots exclusions and noindex metadata are additional discovery controls.

The 192-bit random password lives in AWS Systems Manager Parameter Store as a
SecureString at `/robertboscacci-com/private-trips/password` in `us-west-2`, in the
same account as the existing dev site. Setup uses the AWS SDK so the password is
never passed on a command line or written to a local password file. Access uses
the operator's existing AWS identity; no public or new IAM access is granted.
The default SSM KMS key protects this standard parameter. Initialization refuses
to overwrite it, making retries safe. Normal builds require no secret access.

Read the password in the AWS console when sharing it with family. Do not place
it in Git, logs, screenshots, PRs, URLs, or a committed environment file. The
page disables remembered access, uses a script-hash Content Security Policy,
and sends no password or decrypted content to a server. Reloading locks it.
This is shared-password static encryption, not individual accounts or a server
authorization service: a downloaded old encrypted version cannot be revoked.
Keep private financial information and other account secrets out of the plan.

## Editing

Node 22+, AWS CLI with the existing account credentials, and Hugo are used by
the local workflow. Install pinned tooling with `npm ci` and browser binaries
with `npx playwright install chromium`.

```bash
node scripts/private-trip.mjs decrypt
# Edit data/private-trips/plan.html (ignored; never force-add it).
node scripts/private-trip.mjs encrypt data/private-trips/plan.html
node --test tests/private-trip.test.mjs
node tests/private-trip-browser.mjs
```

The source is static HTML; no scripts, remote fonts, or images are needed.
Browser changes are not saved: this is a shared published reference page.
Delete the ignored plaintext working copy after encryption and validation.
The decrypt command can recover it for future edits.

`STATICRYPT_PASSWORD` can supply a temporary password for isolated test fixtures.
Never put the real password in a shell command or .env file. Unit tests generate
their own random passwords; `node tests/private-trip-browser.mjs --fixture`
tests browser behavior without AWS or access to the family plan. Traces are
disabled because they can retain password field values. Failures emit concise,
non-sensitive diagnostics. No new cloud process or alerting service is needed
for a single static document.

## Dev delivery

Review and commit the encrypted artifact and scripts, with a clean worktree,
then run:

```bash
node scripts/deploy-private-trip.mjs
```

The script verifies the repository, AWS account, and CloudFront alias. It runs
unit, browser, and dependency checks, publishes only the committed encrypted
page to the existing dev bucket, invalidates its route, compares the served
SHA-256 with the committed artifact, and runs the Playwright smoke suite on dev.
No manual dev approval is used. Other dev objects are preserved. Release logs
identify the commit, SHA-256, target, timing, and S3 version when enabled, without
including secrets. Failed checks stop delivery; propagation retries are bounded.
The version-controlled encrypted file is the immutable artifact. Its copy and
verification record are retained under ignored `outputs/private-trip/releases/`.

## Production and rollback

The existing main-branch workflow deploys the full site to production. Keep this
change on its PR branch until users manually smoke-test dev and provide exactly
one production approval, recorded on the PR with the artifact SHA-256, release
tag, and production target. The tag selects the release; it does not approve it.
Do not merge before that approval. The encrypted file must match the dev-tested
SHA-256 when copied into the production site; encryption is never rerun by CI.
Hugo may build the surrounding site, but copies this exact page unchanged.

Use an annotated, previously unused `private-trip/vMAJOR.MINOR.PATCH` tag on the
final default-branch commit. Preserve the approved encrypted file across merge.
After production deployment, verify its bytes and rerun the browser smoke suite
against the production URL. Roll back by restoring a prior encrypted artifact
through a PR, testing dev, then using the same single production approval flow.
Do not rotate the password during rollback unless the restored artifact was
encrypted with that password. Retain release artifacts for recovery.

The repository's pre-existing production workflow has no enforceable approval
gate, and the default branch currently has no protection. This task does not
change repository-wide release policy. Holding this PR open prevents its automatic
production deploy; release approval must be recorded before merging.
