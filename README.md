# tangleroot013 dotfiles

Personal ChromeOS/Crostini environment: shell config, custom tooling, and a handful
of standalone projects, all tracked from a single repo whose work-tree is `$HOME`
itself (see [Setup](#setup) for how that's wired up).

**Environment:** Crostini (hostname `penguin`), zsh + Starship prompt, Python 3.11,
Debian bookworm. Task running via `just`.

#! Setup

This repo is *not* a normal clone-into-a-folder repo. `~/.git` is a pointer file
(`gitdir: ~/.dotfiles.git`), so every plain `git` command run from `$HOME` operates
against `.dotfiles.git` with `$HOME` as the work-tree. To bootstrap on a fresh
machine:

```bash
git clone --separate-git-dir=$HOME/.dotfiles.git <remote-url> /tmp/dotfiles-bootstrap
rsync -a /tmp/dotfiles-bootstrap/ $HOME/
rm -rf /tmp/dotfiles-bootstrap
```

Because the work-tree is the whole home directory, `git clean -fd` / `git checkout -f`
/ hard resets are **repo-wide, not folder-scoped** — they touch everything under
`$HOME` that isn't gitignored. Prefer targeted `git restore <path>` or moving a
directory aside before anything destructive.

## Shell environment

- `.zshrc` is the main config; `.zshrc.local` holds machine-local additions and
  Claude-assisted helper functions.
- Additions to `.zshrc.local` are wrapped in marker comments so they're easy to
  find and remove:
  ```
  # >>> claude:<name> >>>
  ...
  # <<< claude:<name> <<<
  ```
- Custom functions include `pages-publish` (locates and publishes the
  `ez_bookmarks` GitHub Pages site from anywhere), plus earlier additions like
  `fkill`, `proj`, `covgaps`, `gdf`.

## Projects

- **ez_bookmarks** — GitHub Pages resource-library site with live search/filtering.
  Published via `just publish-pages` (run from inside the repo) or `pages-publish`
  (run from anywhere). Wiki lives in the separate `ez_bookmarks.wiki` clone —
  don't confuse the two when running git commands.
- **ez_jukebox** / **ez_jukebox_beta** — MPD-based music player with a
  `Restart=always` systemd watcher (`ez_jukebox_watcher.sh`) and dedup tooling.
- **ez_media_cleaner** / **ez_tagger** / **metaclean** — SHA-256 dedup, tag
  fixing, and privacy-focused metadata scrubbing for the music library.
- **penguin-diag** — CLI diagnostic tool for this Crostini container.
- **stunning-octo-funicular (CerebroFlow)** — hub repo with a staged CI/CD
  pipeline (`ship.py`).
- **chromebook-mullvad-wireguard** — Mullvad VPN tunnel setup for Crostini via
  `wg-quick` in userspace mode (no kernel WireGuard module in this container):
  ```bash
  sudo env WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go wg-quick up wg0
  ```
  `wg0.conf` uses `Table = off` with custom `PostUp`/`PreDown` scripts to route
  around the tunnel endpoint and set `wg0` as the metric-50 default route.

## Known issues

- **Repo pollution (2026-09-04):** a merge from `origin/main` introduced ~20
  unfamiliar files at the repo root (`dockerfile.dockerfile`, `makefile.makefile`,
  `MIT License.txt`, etc.) of unknown origin. Pending review — check
  `git log --oneline -- <file>` per file before trusting or deleting them.
- **WireGuard key drift:** `/etc/wireguard/wg0.conf`'s `PrivateKey` may not match
  the key registered as the "solid lizard" device on the Mullvad account, likely
  from an earlier auto-remediation script overwriting it. Verify with
  `wg pubkey` against the conf's key before assuming the tunnel is authenticating.
- A stale custom parsing script, `wireguard_setup.sh`, truncates base64 values
  containing `=` (uses `awk -F'='` instead of splitting on the first `=` only).
  Superseded by plain `wg-quick`; safe to delete once confirmed unused.

## Safety nets

- `repo-safety-backups/`, `home_repo_backup.git/`, `session_scripts_archive/` —
  point-in-time backups from past cleanup work.
- Backup branches follow the pattern `backup-before-merge-<timestamp>`.
