# Fork: free (Pro-unlocked) self-built AltTab

Status: current as of 2026-11-09, `free` branch at `4199f61d`, upstream base `ec4f94a8` (AltTab 11.10.1 + README commit).

## Why this fork exists

- Goal: use AltTab's window switcher with **two** shortcuts (⌘Tab for all windows, ⌘` for the active app's windows on **all Spaces**) without paying for Pro.
- Upstream AltTab is GPL-3.0, but since 11.x the official signed binaries gate extra shortcut slots (index ≥ 1), search, extra styles and auto-size behind Pro after a 14-day trial. Gate for shortcuts: `ProFeature.extraShortcut(index:)` checked in `src/switcher/ShortcutAction.swift` (`execute(_:)`).
- Upstream's own FAQ states the Pro license applies to the pre-built binaries, and the source can be built yourself (https://alt-tab.app/, FAQ "Is AltTab open-source?").
- Alternatives were evaluated first and rejected; see [window-switcher-research.md](./window-switcher-research.md).

## Branch layout

| Branch | Content | Rule |
| --- | --- | --- |
| `master` | Untouched mirror of `lwouis/alt-tab-macos` | **Never push to it.** Actions are enabled on this fork, and upstream's `.github/workflows/ci_cd.yml` runs on `master` pushes; it needs the upstream author's secrets and will fail. |
| `free` | Upstream + fork patch + build workflow + `/wiki` + `/spec` | All fork work happens here. |

## The patch

Everything functional is compiled in only when the Swift condition `PRO_BUILD` is set, so without it the code is identical to upstream. That keeps upstream merges small.

| File | Change | Reason |
| --- | --- | --- |
| `src/pro/license/LicenseManager.swift` | `computeState()` returns `.pro` under `#if PRO_BUILD`, original body in `#else` | Unlocks every Pro feature. Written as `#if/#else`, not an early `return`: the project sets `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` (`config/base.xcconfig`), and code after `return` would warn "will never be executed" and fail the build. |
| `src/vendors/SparkleDelegate.swift` | Adds `updater(_:mayPerform:) throws` under `#if PRO_BUILD`, which always throws | Blocks every Sparkle update check, so the official updater can never replace this build with the upstream (paywalled) binary. The vemonet fork does not do this. |
| `scripts/build_free.sh` (new) | Release build with `SWIFT_ACTIVE_COMPILATION_CONDITIONS=PRO_BUILD`, signing override, signature verification | Upstream Release config signs with `Developer ID Application: Louis Pontoise` (`config/release.xcconfig`), which we do not have. |
| `.github/workflows/build_free.yml` (new) | Builds on push to `free`, uploads `AltTab-free.zip` artifact (30-day retention) | No local Xcode on the maintainer's Mac (only Command Line Tools). |
| `FORK.md` (new, repo root) | Short human-facing summary of the above | |

Commits: `44aed0d3` (patch, script, workflow, FORK.md), `4199f61d` (build-script fix).

## Build details and gotchas

- **Runner / Xcode:** `runs-on: xcode-27`, `Xcode_27.1.app`, copied from upstream `ci_cd.yml`. Upstream moved there on 2026-10-22 (commit `954a1113`) because the macOS 26 / Xcode 26.6 build "stopped making progress". Keep in sync with upstream's `ci_cd.yml` when merging.
- **Version:** `CURRENT_PROJECT_VERSION` comes from `git describe --tags`, falling back to the first version heading in `changelog.md` (the fork has no tags). Commit `4199f61d` fixed a crash here: under `set -euo pipefail`, a failing `git describe` inside `$(...)` exited the script with code 128.
- **Code-signing flags:** overridden to `--deep --options runtime`, dropping upstream's `--timestamp`, which targets Apple's timestamp service for Developer ID signing. The hardened runtime stays on. `alt_tab_macos.entitlements` already has `com.apple.security.cs.disable-library-validation`, so ad-hoc signing loads the embedded frameworks fine.
- **Signing identity:** the script uses the `Local Self-Signed` certificate when it is in the keychain, otherwise ad-hoc (`-`). In CI, optional secrets `FREE_P12_CERTIFICATE` (base64 p12) and `FREE_P12_PASSWORD` import a certificate and set `CODE_SIGN_IDENTITY=Local Self-Signed`. **These secrets are not set yet**, so CI builds are ad-hoc signed.
- **Consequence of ad-hoc signing:** macOS ties Accessibility and Screen Recording grants to the code signature, so every new build must be re-granted (remove the old AltTab entries in System Settings → Privacy & Security, then allow again). A stable self-signed certificate (generate with `scripts/codesign/generate_selfsigned_certificate.sh`, CN `Local Self-Signed`) would avoid this.
- **Bundle ID is unchanged** (`com.lwouis.alt-tab-macos`), so the build reuses the user's existing AltTab preferences. Root `AGENTS.md` has a License/Keychain invariant about keeping the signature stable. It doesn't apply in practice here, because `PRO_BUILD` never reads keychain license items.
- **Debug vs Release:** the vemonet fork builds the Debug scheme with `DEBUG PRO_BUILD`. This fork builds Release (optimized, `-Osize`, ThinLTO) without `DEBUG`.

## Verification performed (2026-11-09)

- CI run https://github.com/GyroZepelix/alt-tab-macos-free/actions/runs/42664036695 succeeded.
- Downloaded artifact: `CFBundleShortVersionString` 11.10.1, bundle ID `com.lwouis.alt-tab-macos`, `codesign --verify --deep --strict` OK, flags `adhoc,runtime`, the update-block error string is present in the binary, and there is no quarantine xattr.
- Installed to `/Applications/AltTab.app` and launched.
- **Unverified:** in-app UI confirmation that no Trial/Pro badges remain and that shortcut 2 works after the trial window. Verified only by reading the code.

## Updating to a new upstream release

```sh
git remote add upstream https://github.com/lwouis/alt-tab-macos.git   # once
git fetch upstream --tags
git switch free
git merge vX.Y.Z            # conflicts, if any, are in the two patched Swift files
git push                    # triggers build_free.yml
gh run download <run-id> -R GyroZepelix/alt-tab-macos-free -n AltTab-free
```

Then quit AltTab, replace `/Applications/AltTab.app`, and re-grant permissions (ad-hoc builds).

When merging, re-check that:

- `LicenseManager.computeState()` is still the single source of license state (upstream changed this file by ~77 lines between 11.8.0 and 11.10.1, e.g. team licenses).
- Shortcut gating still goes through `ProFeature` and license state.
- Upstream's Xcode/runner pin in `ci_cd.yml` has not moved.

## Open follow-ups

- Optional: create a stable self-signed certificate and set the `FREE_P12_*` secrets, so permissions survive rebuilds.
- Optional: automate weekly upstream merges (vemonet's workflow does this, but its sync broke because `GITHUB_TOKEN` cannot push changes to `.github/workflows/**`; it would need a PAT).
