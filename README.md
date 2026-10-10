# aur-audit

> [!WARNING]
> **This project was vibe coded through Claude Opus 5.5.** I described what I
> wanted, and the code, tests, and this README were written by AI, then tested
> by me on my own Arch Linux (Omarchy) system. I'm being fully transparent
> about that, so **use it with caution**: read the code before trusting it with
> your system, and don't treat it as a replacement for reviewing PKGBUILDs
> yourself.

A security check for [AUR](https://aur.archlinux.org/) packages on Arch Linux.
It audits AUR packages for signs of malware and **cancels the build or install**
if it finds anything hazardous.

It checks at two points:

1. **Before yay builds anything.** A small wrapper around `makepkg` audits the
   PKGBUILD that yay downloaded *before* any of its code runs, before sources
   are downloaded, and before yay asks to import PGP keys.
2. **Before pacman installs anything.** A pacman hook audits the built package
   (its install script and the files inside it) and aborts the transaction if
   it is hazardous.

Packages from the official repos are skipped.

## What it checks

| Area | Blocks if… | Warns if… |
|---|---|---|
| **AUR reputation** | Package is under 14 days old with fewer than 10 votes; name imitates an official package with a suffix like `-fix`, `-patch`, `-update` | Orphaned, barely used, young with few votes, or no longer on the AUR |
| **Sources** | Downloads from a raw IP address, paste sites, file-sharing sites, URL shorteners, Discord's CDN, ngrok; upstream GitHub repo is brand new with almost no stars | Plain http, `SKIP` checksums on non-signature files, GitHub repo with very few stars |
| **PKGBUILD / install script** | `curl … \| sh`, running decoded base64, reverse shells, editing sudoers, cron, `ld.so.preload`, `.bashrc`, SSH keys. Install scripts (which run as root) that download anything | setuid bits, enabling services, disabling security controls, obfuscated-looking blobs |
| **Package contents** | Files in `/home`, `/root`, sudoers, cron, `ld.so.preload` | setuid binaries, autostart, PAM, or SSH config changes |

If the AUR can't be reached, AUR packages are blocked rather than allowed
unverified.

When something is blocked, the full report is saved to
`~/aur-audit-blocked-<date>_<time>.txt`.

## Requirements

- Arch Linux (or an Arch-based distro) with `pacman`
- `python` (3.10+), `libarchive` (`bsdtar`)
- [`yay`](https://github.com/Jguer/yay) for the build-time check (the pacman hook works without it)

## Install

```sh
git clone https://github.com/TheDoodAbides87/aur-audit.git
cd aur-audit
sudo ./install.sh
```

This installs:

- `/usr/local/bin/aur-audit`: the auditor
- `/usr/local/bin/aur-audit-makepkg`: the makepkg wrapper for yay
- `/etc/pacman.d/hooks/01-aur-audit.hook`: the pacman hook
- `/etc/aur-audit/allowlist`: packages you've reviewed and trust

Then turn on the build-time check (as your normal user, **not** root):

```sh
yay -Y --makepkg /usr/local/bin/aur-audit-makepkg --save
```

> Use `yay -Y`. Plain `yay --makepkg … --save` also starts a full system upgrade.

## Usage

It runs automatically through yay and pacman. You can also run it by hand:

```sh
aur-audit check some-package      # audit an AUR package before installing it
aur-audit dir .                   # audit a PKGBUILD folder (e.g. before running makepkg yourself)
aur-audit file foo.pkg.tar.zst    # audit an already-built package file
```

## When it blocks something you trust

Review the package yourself, then add the `name version` line that the block
message shows to `/etc/aur-audit/allowlist`:

```
some-package 1.2.3-1
```

Only that exact version is allowed, so every update gets audited again.

## Limitations

- **The checks are pattern-based.** They catch common, known malware techniques,
  but a careful attacker could write a PKGBUILD that gets past them. Passing the
  audit does not mean a package is safe.
- Running `makepkg` by hand skips the build-time check; run `aur-audit dir .` first.
- Other AUR helpers (paru, etc.) only get the pacman-hook check, which runs
  *after* the package has already been built.
- GitHub reputation checks use the unauthenticated GitHub API (60 requests/hour);
  when rate-limited, that check is skipped with a note.

## Uninstall

```sh
yay -Y --makepkg makepkg --save
sudo rm /usr/local/bin/aur-audit /usr/local/bin/aur-audit-makepkg /etc/pacman.d/hooks/01-aur-audit.hook
sudo rm -r /etc/aur-audit
```

## License

[MIT](LICENSE): anyone can use, copy, modify, and share this freely. It comes
with no warranty; see the license for details.
