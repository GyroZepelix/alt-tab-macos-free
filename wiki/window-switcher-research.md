# Research: macOS window switchers and Spaces (why this fork)

Research date: 2026-11-09. User machine: macOS 26.4, arm64. Versions noted per tool. Third-party facts come from each project's source or GitHub API at that date. Re-verify before relying on them.

## The problem

- Native ⌘` only cycles the front app's windows **on the current Space**. There is no system setting to change this.
- Use case: two Brave windows (different profiles) on different Spaces. ⌘` should reach both.

## Key technical finding: AX element-ID brute force

- macOS's public Accessibility API (`kAXWindowsAttribute`) only returns windows on the current Space. Switchers find other-Space windows by brute-forcing `_AXUIElementCreateWithRemoteToken` over an app's AX element IDs.
- Measured on the user's Brave (single process; both profiles share one PID): the current-Space window had AX ID **44**, and the other-Space window had AX ID **1195**. Chromium hands out IDs in increasing order, so windows created later in a long session get high IDs. Measured with a small Swift probe that scanned IDs 0..<5000 in about 0.08 s.
- Scan limits per tool:

| Tool | Version checked | Brute-force range | Finds ID 1195? | Evidence |
| --- | --- | --- | --- | --- |
| BetterCmdTab | 26.7 / 26.8-beta.10 | `0..<1024`, 0.25 s wall-clock budget | No (intermittently showed cached windows) | `BetterCmdTab/Windows/WindowEnumerator.swift` (`bruteForceLimit`, `bruteForceTimeBudget`) |
| DockDoor | 1.42.4 | `0..<1000` | No | `DockDoor/Extensions/AXUIElement.swift` (`windowsByBruteForce`) |
| AltTab ≤ 11.3.0 (justinbaduaa fork base) | 11.3.0 | `0..<1000` | No | fork's `src/macos/api-wrappers/AXUIElement.swift` |
| AltTab ≥ 11.8.0 (current upstream) | 11.10.1 | Adaptive, resumable sweep with per-attempt time budget; upstream notes cover IDs up to ~30000 | Yes (by design; not yet confirmed in UI) | `src/macos/api-wrappers/AXUIElement.swift` (`bruteForceElements`), `src/util/SchedulingPolicy.swift` |

- Side observation: QEMU / Android Emulator showed one or two entries because it really has two AX windows (main `AXStandardWindow` plus a narrow `AXDialog` toolbar). Whether the toolbar appears depends on each switcher's filters. It isn't a bug.

## Alternatives evaluated (2026-11-09)

| Tool | License | Maturity signals | Outcome |
| --- | --- | --- | --- |
| BetterCmdTab (`rokartur/BetterCmdTab`) | GPL-3.0 | Created 2026-05, ~865 stars, mostly single maintainer | Rejected: 1024-ID / 0.25 s cap. Note: its "Tap Shift to step backwards" default is the Shift-jumps-back annoyance. |
| DockDoor (`ejbills/DockDoor`) | GPL-3.0 | Created 2024-06, ~6.5k stars, ~46 contributors, notarized | Rejected: 1000-ID cap. Supports ⌘` via "Alternate Shortcuts" with mode "Active App Only". |
| Open Contexts (`zshnb/open-contexts`) | Apache-2.0 | ~7 weeks old, single maintainer | Not tried. |
| WindowHop (`martonpaulo/windowhop`) | GPL-3.0 | AltTab v10.12 derivative, needs macOS 26 + Apple silicon | Not tried; only lists other-Space windows after visiting that Space. |
| AltTab official free tier | GPL-3.0 source, paid binaries | Mature | Works, but only shortcut slot 1 stays free after the trial. |

## Free AltTab forks evaluated

| Fork | Change vs upstream | State on 2026-11-09 | Verdict |
| --- | --- | --- | --- |
| `vemonet/alt-tab-macos-free` | 4-line `#if PRO_BUILD return .pro` in `LicenseManager.swift`, plus a weekly upstream-sync workflow (Debug build) | Stuck at 11.8.0. The sync step failed 5 weekly runs in a row (Oct 12 to Nov 9), likely because `GITHUB_TOKEN` cannot push upstream's `.github/workflows` changes | Approach adopted here, improved (Release build, update checks blocked). |
| `justinbaduaa/alt-tab-macos-free` | Removes Pro code (~8.5k lines deleted), adds features, own Sparkle feed | Last push 2026-06-14, base 11.3.0 | Rejected: stale and has the 1000-ID limit. |
| `rayleighxu7/alt-tab-macos` | Single squashed "initial commit", 573 files differ from upstream, 1 star | Unauditable | Rejected. |

## Sources

- https://alt-tab.app/ and https://alt-tab.app/pricing (free vs Pro features)
- https://github.com/lwouis/alt-tab-macos/issues/5908 (community reaction to Pro rollout)
- https://github.com/rokartur/BetterCmdTab, https://bettercmdtab.app/docs/config-reference
- https://github.com/ejbills/DockDoor
- https://github.com/vemonet/alt-tab-macos-free, https://github.com/justinbaduaa/alt-tab-macos-free, https://github.com/rayleighxu7/alt-tab-macos
