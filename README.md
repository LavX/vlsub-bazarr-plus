# VLSub Bazarr+

A VLC extension that searches and downloads subtitles via a self-hosted [Bazarr+](https://github.com/LavX/bazarr) instance. Configure your subtitle providers once in Bazarr+, use them from every VLC on your LAN.

Hard fork for the Bazarr+ compat endpoint. Not tracking upstream.

## Prerequisites

- VLC 3.0 or newer (native, Flatpak `org.videolan.VLC`, or Snap `vlc`).
- A running Bazarr+ instance with the **External Integration** endpoint enabled
  (Settings → External Integration → toggle on, copy the API token, restart Bazarr+).

## Install

### One-liner (Linux, macOS)

```bash
curl -sSL https://raw.githubusercontent.com/LavX/vlsub-bazarr-plus/main/scripts/install.sh | bash
```

The script detects native, Flatpak, and Snap VLC installs and copies `vlsubcom.lua` into every extensions dir it finds.

### One-liner (Windows, PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/LavX/vlsub-bazarr-plus/main/scripts/install.ps1 | iex
```

### Manual

Copy `vlsubcom.lua` to your VLC extensions dir:

| Install type | Path |
|---|---|
| Linux native | `~/.local/share/vlc/lua/extensions/` |
| Linux Flatpak | `~/.var/app/org.videolan.VLC/data/vlc/lua/extensions/` |
| Linux Snap | `~/snap/vlc/current/.local/share/vlc/lua/extensions/` |
| macOS | `~/Library/Application Support/org.videolan.vlc/lua/extensions/` |
| Windows | `%APPDATA%\vlc\lua\extensions\` |

Restart VLC.

## Configure

1. In VLC: **View → VLSub Bazarr+**.
2. Click **⚙️ Config**.
3. Fill in:
   - **Bazarr+ Base URL**: `http://<bazarr-host>:6767`
   - **Bazarr+ API Key**: the token from Bazarr+ Settings → External Integration.
4. Click **💾 Save**.

If the credentials are valid you get `Login successful` and quota info. The session is cached on disk so subsequent launches don't re-authenticate.

## Use

- **View → VLSub Bazarr+** while a video is playing for hash-based search, or without a video for title-based search.
- Fill in **Title / Season / Episode** if auto-detection is wrong.
- Pick up to **3 subtitle languages**.
- Double-click a row or use **Download**. The subtitle is saved next to the video file and loaded into the current playback.

Each result row: `LANG·provider  [indicators]  filename  · uploader  · downloads↓  · date`.

Indicators:

| Mark | Meaning |
|---|---|
| `◉` | hash match (exact) |
| `✓` | trusted uploader |
| `HD` | HD release |
| `♿` | hearing-impaired |
| `AI` | AI-translated |
| `MT` | machine-translated |

## Troubleshooting

| Symptom | Fix |
|---|---|
| **VLSub Bazarr+ missing from View menu** | VLC only scans extensions at launch. Fully quit VLC (`pkill -f vlc.bin` for Flatpak) and relaunch. |
| **Config dialog freezes after Save** | Wrong URL or port. Worst-case freeze is 5 s. Check **Tools → Messages** (verbosity 2) for the `[VLSub] POST …` line, fix the URL, Save again. |
| **Login failed (401)** | API token doesn't match. Regenerate in Bazarr+ Settings → External Integration and re-paste. |
| **Login failed (405 / 404)** | Base URL is wrong, or Bazarr+ compat endpoint isn't enabled. Base URL is just the host and port, e.g. `http://host:6767`, no path suffix. |
| **No results** | Bazarr+ returned empty. Check Bazarr+ logs; providers may have errored or timed out. 503 with `x-reason: upstream` means all configured providers failed. |
| **Results look stale** | Bazarr+ caches search results server-side. Adjust `cache_ttl_seconds` in Bazarr+ `External Integration` settings. |
| **Download link 404** | `file_id` expired (60 min default TTL). Re-search. |

To capture a live debug log:

```bash
# Linux Flatpak
flatpak run org.videolan.VLC --verbose=2 --file-logging \
  --logfile=$HOME/.var/app/org.videolan.VLC/data/vlc.log
```

Then grep `\[VLSub\]` in the logfile.

## Related

- [Bazarr+](https://github.com/LavX/bazarr): the server this plugin talks to.
- [jellyfin-plugin-bazarr-plus](https://github.com/LavX/jellyfin-plugin-bazarr-plus): same compat endpoint, Jellyfin-side consumer.

## License

GPL v3. See [LICENSE](LICENSE).
