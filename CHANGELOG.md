# Changelog

All notable changes to VLSub Bazarr+ are documented here.

Format loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Unreleased

### Added
- Bazarr+ compat endpoint support: rewrites the upstream API host calls to a configurable Bazarr+ host.
- Config fields: `Bazarr+ Base URL` and `Bazarr+ API Key`. Accepts both `http://host:6767` and `http://host:6767/api/v1/`.
- Provider display: parses `provider:uploader` shape from Bazarr+'s `uploader.name` and shows `LANG·provider` per row.
- Install script: detects Flatpak and Snap VLC installs in addition to native on Linux.

### Changed
- Rebranded from the upstream extension to `VLSub Bazarr+`.
- Dropped OS.com username/password UI. Bazarr+ ignores creds, so we stub them inline.
- Quality indicators moved to BMP-safe glyphs so VLC's Qt widget actually renders them:
  `◉` hash match, `✓` trusted, `HD`, `♿` HI, `AI`, `MT`.
- HTTP client defaults: 5 s timeout, 0 retries. `set_timeout`/`set_retries` callers are clamped so a misbehaving upstream can't wedge the UI.
- `parse_url` now returns the URL port; HTTP-only TCP path honors non-80/443 ports (Bazarr+ runs on 6767).
- Auto-updater points at the LavX fork releases; upstream update channel is disconnected.
- `test_network_connectivity` probes the configured Bazarr+ URL instead of Google, httpbin, and the upstream host.
- Language API fetch is skipped on first run until Bazarr+ is configured (prevents a 30 s freeze against unreachable upstream).

### Removed
- IP geolocation probe (`api.myip.com`) on first run.
- Dead `test_headers()` diagnostic that would have leaked the API token to a third-party header-echo page.
- upstream branding (app title, descriptor, error strings, help text, install dialog labels, GitHub repo links).
- Upstream docs tree (`docs/faq.md`, `installation.md`, `usage.md`, `languages.md`, `troubleshooting.md`).
- Upstream logo, screenshots, FUNDING.yml, issue templates, release workflow.

### Fixed
- `add_value(text, 0)` crash: VLC 3.0.23's Lua binding rejects id=0, so dropdown ids are shifted by +1 and decoded in four places (`apply_config`, `getSelectedLanguages`, `getUserSelectedLanguages`, `searchIMBD`, `applySubtitleSortingSelection`).
- URL rewrite regex preserves `/api/v1/` when the user's base URL doesn't include it.
- Login-failure path guards `error_data` against non-JSON bodies before indexing.
