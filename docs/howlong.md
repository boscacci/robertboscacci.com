# How Long?

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
click updates the database atomically. Open pages refresh about every 10 seconds.

## Development

On OptiPlex, run `npm ci`, `npm run test:howlong` and then run the checked-in
deployment script from a clean reviewed commit. Supply the initial date in the
`HOWLONG_INITIAL_DATE` environment variable in `YYYY-MM-DD` form.

```bash
bash scripts/deploy-howlong-dev.sh
```

The script archives the tracked service, retains the SHA-256 and commit, and
links the user service to that release. It verifies HTTPS and tests that a
browser-supplied identity is overwritten. Tailscale Funnel stays disabled for
the dev endpoint. The deployment record is in `~/.local/share/howlong/dev/dev.json`.
Service logs are available through `journalctl --user -u howlong-dev.service`.

On Tailscale, open the dev URL in two tabs. Check that four clicks show progress
and keep the original date, the fifth click shows zero days, and the other tab
updates. A non-owner's account should see the count without the reset control.

Production requires an explicit release approval after manual dev smoke testing.
