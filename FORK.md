# Fork notes

Self-built AltTab with every Pro feature unlocked. AltTab is GPL-3.0; the Pro license only covers the
official pre-built binaries. If you can, support the original author: https://alt-tab.app/pricing

## Patch (compiled in only with the `PRO_BUILD` Swift flag)

- `src/pro/license/LicenseManager.swift`: `computeState()` returns `.pro`.
- `src/vendors/SparkleDelegate.swift`: refuses every update check, so the official updater can never
  replace this build with the upstream binary.
- `scripts/build_free.sh`: Release build with `PRO_BUILD`, signed with "Local Self-Signed" (or ad-hoc).

## Build

Requires full Xcode.

```sh
scripts/codesign/setup_local.sh   # once: creates the "Local Self-Signed" signing certificate
scripts/build_free.sh
```

## Update to a new upstream release

```sh
git remote add upstream https://github.com/lwouis/alt-tab-macos.git   # once
git fetch upstream --tags
git merge vX.Y.Z      # resolve conflicts in the two files above if any
scripts/build_free.sh
```
