# Contributing

This is a **hard fork** maintained for one operator's Bazarr+ setup. Parity with the upstream project is not a goal, and this repo does not track upstream changes.

Pull requests are not actively being reviewed. If you found a bug that matters to you, your options are:

- **Fork this fork.** GPL v3, help yourself. That's what this repo is.
- **File an issue.** No SLA, but useful reports (steps to reproduce, VLC version, a `[VLSub]` log snippet at verbosity 2) may get addressed when the maintainer hits the same thing.
- **Talk to Bazarr+ upstream** if your bug is on the compat endpoint side: [github.com/LavX/bazarr](https://github.com/LavX/bazarr).

## If you insist on a PR

Keep it small, single-purpose, and include a one-line rationale in the commit body. No upstream-compat shims, no re-adding third-party service branding, no analytics/telemetry, no auto-update that reaches outside this repo.

Run a syntax check before pushing:

```bash
luajit -bl vlsubcom.lua > /dev/null
```

## Reporting security issues

Email the address listed in the commit author field. Don't open a public issue for an API-key leak, SSRF, or anything that trusts a remote input.
