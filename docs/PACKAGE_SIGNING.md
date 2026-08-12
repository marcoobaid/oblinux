# Package signing & Chaotic-AUR (2026-08-12)

Two infrastructure additions, done together since they share the same
underlying mechanism: `oblinux_repo` packages are now signed
(`SigLevel = Optional TrustedOnly` → `Required TrustedOnly`), and
Chaotic-AUR (`https://aur.chaotic.cx`) — community-maintained prebuilt AUR
packages — is wired in as a repo.

## The OBLinux signing key

- **ed25519**, generated 2026-08-12 on the build machine (user `baba`),
  no passphrase (`%no-protection` — needed for `update_repo.sh` to sign
  non-interactively).
- Fingerprint: `D0514F69650F2B9725E12E26297CB74B36C93A92`
- UID: `OBLinux Repo Signing Key <repo@oblinux.local>`
- Private key: `~/.gnupg/private-keys-v1.d/D81C2083C6FC7326D507D60759938EF9CF5FE50D.key`
  on the build machine (filename is the key's *keygrip*, a different
  identifier than the fingerprint above — this is normal GnuPG internal
  storage, not a mismatch/error).
- Revocation certificate:
  `~/.gnupg/openpgp-revocs.d/D0514F69650F2B9725E12E26297CB74B36C93A92.rev`
  — needed to cleanly invalidate this key later if it's ever lost or
  compromised. Back this up; without it, a lost/compromised key can't be
  properly revoked.
- Backed up (build machine → secure cloud storage): the `.key` file, the
  `.rev` file, and a portable secret-key export
  (`gpg --export-secret-keys --armor D0514F69650F2B9725E12E26297CB74B36C93A92`)
  — the last one is the one that actually restores cleanly on a fresh
  machine via `gpg --import`, since it doesn't depend on GnuPG's internal
  keygrip/keybox linkage the way the raw `.key` file does.

### How it was generated

```bash
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: sign
Name-Real: OBLinux Repo Signing Key
Name-Email: repo@oblinux.local
Expire-Date: 0
EOF
gpg --list-keys --keyid-format long repo@oblinux.local
gpg --export D0514F69650F2B9725E12E26297CB74B36C93A92 > oblinux-repo.gpg
```

The exported file is the **public** key only — safe to commit/share.
Confirmed correct format:
`file oblinux-repo.gpg` → `OpenPGP Public Key Version 4, ... EdDSA;
User ID; Signature; OpenPGP Certificate`, 246 bytes.

## Signing packages (`oblinux_repo`)

`x86_64/update_repo.sh` now signs both layers pacman actually checks:

1. Each individual `.pkg.tar.zst` — `gpg --detach-sign`, producing a
   `.sig` file alongside it (this is what pacman fetches and checks per
   package; `repo-add -s` alone does **not** sign individual packages,
   only the database — verified against `repo-add`'s own manual, not
   assumed).
2. The repo database itself — `repo-add -s -k <KEYID> --include-sigs`.

Packages already published (`calamares-3.4.2-2`, `paru-2.1.0-2`,
`ckbcomp-1.248-1`) were built and published **before** this key existed,
so they have no `.sig` yet — now that `SigLevel = Required`, they need to
be re-signed and republished (`./update_repo.sh`, then commit/push) before
the next `mkarchiso` build, or `pacstrap` will fail to resolve them
(unsigned package, signature required). This has to run on the build
machine, where the private key actually lives — not something that can be
done from a plain clone elsewhere.

## Getting trust actually baked into the ISO

Dropping a `.gpg` file into `airootfs/usr/share/pacman/keyrings/` is *not*
enough on its own — confirmed against archiso's real `pacman-init.service`
unit, which only ever runs `pacman-key --populate archlinux`. It doesn't
scan and populate every keyring found in that directory automatically, so
without doing something more, the keys would be present on disk but never
imported into pacman's actual trust database. Three places needed
covering, matching the three moments trust actually gets used:

1. **Build time** (`mkarchiso`'s `pacstrap`) — uses the **build machine's
   own** system pacman keyring, not anything from the profile. One-time
   setup required on the build machine before the *next* build (see
   below) — this is the one step this project's config genuinely can't
   do on its own, since it's the host machine's own trust store.
2. **Live session** — a `pacman-init.service` drop-in
   (`airootfs/etc/systemd/system/pacman-init.service.d/50-oblinux-custom-keyrings.conf`)
   adds `pacman-key --populate chaotic oblinux-repo` as an extra
   `ExecStart=` (oneshot services run multiple `ExecStart=` lines in
   sequence, so this appends to the stock unit's own `--populate
   archlinux` rather than replacing it).
3. **Installed system** — `pacman-init.service` is masked post-install
   (it's live-only, see `shellprocess-final.conf`'s existing reasoning),
   so nothing from step 2 applies there. `shellprocess-final.conf`'s
   post-install keyring-refresh step (added when the archlinux-keyring
   trust bug was fixed — see `docs/TESTING.md`) now also populates
   `chaotic` and `oblinux-repo`.

### One-time build-machine setup (do this before the next build)

`pacstrap` verifies signatures against the **build machine's own**
`/etc/pacman.d/gnupg`, regardless of what's in the profile — the profile's
keyring files only ever affect the *built image*, never the machine doing
the building. On the build machine (as `baba`, with sudo):

```bash
sudo pacman-key --add /path/to/oblinux-repo.gpg
sudo pacman-key --lsign-key D0514F69650F2B9725E12E26297CB74B36C93A92
```

(`oblinux-repo.gpg` is the same public key file now at
`airootfs/usr/share/pacman/keyrings/oblinux-repo.gpg` in this repo.)

Chaotic-AUR isn't in `packages.x86_64` yet, so this isn't required for a
build to succeed today — only needed on the build machine if/when it's
actually used there (e.g. testing a `paru -S chaotic-aur/...` pull, or
once a default-app-list package is sourced from it):

```bash
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
```

## Chaotic-AUR — verified against the real thing, not reconstructed

`airootfs/usr/share/pacman/keyrings/chaotic.{gpg,-trusted,-revoked}` and
`airootfs/etc/pacman.d/chaotic-mirrorlist` are extracted **verbatim** from
Chaotic's own `chaotic-keyring` and `chaotic-mirrorlist` packages
(downloaded from `cdn-mirror.chaotic.cx`, unpacked directly), not
hand-written from the setup instructions on
[aur.chaotic.cx/docs](https://aur.chaotic.cx/docs). Their own `.INSTALL`
script confirms the populate mechanism: `pacman-key --populate chaotic` —
matching the keyring name (`chaotic`, not `chaotic-aur`) used in the
`pacman-init.service` drop-in and `shellprocess-final.conf` above.

`chaotic-trusted` contents (trust level `4`, "full" — matches how a
distributed repo signing key should be trusted, not `6`/"ultimate", which
would only make sense on a machine that actually holds the private key):

```
EF925EA60F33D0CB85C44AD13056513887B78AEB:4:
67BF8CA6DA181643C9723B4ED6C9442437365605:4:
```

`pacman.conf` (both the build-time root file and
`airootfs/etc/pacman.conf`) got a `[chaotic-aur]` section pointing at the
shipped mirrorlist — same `Include =` line Chaotic's own docs recommend,
just backed by a file already on disk instead of a separate package
install. Not yet added to `packages.x86_64` — that's a curated-app-list
decision for later, this just makes the repo available and trusted.

## Status

Both prerequisites are done as of 2026-08-12: `oblinux_repo`'s three
packages were re-signed and republished via `update_repo.sh`
(`calamares-3.4.2-2-x86_64.pkg.tar.zst.sig`,
`ckbcomp-1.248-1-any.pkg.tar.zst.sig`, `paru-2.1.0-2-x86_64.pkg.tar.zst.sig`,
plus the signed database — commit `85a2258`), and the build machine's own
`pacman-key --add`/`--lsign-key` for `oblinux-repo` is done.

**Not yet done**: none of this has actually been through a build/boot
test yet — next `mkarchiso` build is the real test, both for whether
`pacstrap` resolves the now-signed `oblinux_repo` packages correctly and
whether the live/installed-system keyring population (the
`pacman-init.service` drop-in, the `shellprocess-final.conf` step) works
as designed.
