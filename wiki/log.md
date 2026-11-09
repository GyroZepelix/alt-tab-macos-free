# Wiki Log

Curated append-only timeline of durable wiki maintenance events. This is not a codebase changelog, commit log, or session transcript.

Use this shape for new entries:

- Heading: `## [YYYY-MM-DD] <kind> | <short title>`.
- Trigger: why the wiki was updated.
- Inputs: source paths, commit ranges, specs, verification, outcomes, URLs, or raw files used as evidence.
- Wiki pages changed: wiki files changed.
- Verification: checks or source verification.
- Notes: gaps, conflicts, stale areas, or exceptions.

## [2026-11-09] install | repo wiki template

- Trigger: user requested installation from `https://git.dgjalic.com/dgjalic/repo-wiki-template`.
- Inputs: protocol version 2.2.1/schema-2 payload from `repo-wiki-template/install/template/`.
- Wiki pages changed: `wiki/AGENTS.md`, `wiki/index.md`, `wiki/log.md`, `wiki/state.md`, `wiki/raw/README.md`.
- Verification: required files and managed regions exist; existing files were preserved or merged; protocol validation result was recorded.
- Notes: installed payload may also create or merge root and spec files; initial codebase ingest is still needed.

## [2026-11-09] ingest | fork delta and window-switcher research

- Trigger: user asked for a handoff record of the fork changes so future work has context.
- Inputs: commits `44aed0d3`, `4199f61d` on `free` (base `ec4f94a8`); `src/pro/license/LicenseManager.swift`, `src/vendors/SparkleDelegate.swift`, `scripts/build_free.sh`, `.github/workflows/build_free.yml`, `FORK.md`; CI run 42664036695; AX probe measurements on the user's Brave; source of BetterCmdTab 26.7/26.8-beta.10, DockDoor 1.42.4, vemonet/justinbaduaa/rayleighxu7 forks; URLs listed in the research page.
- Wiki pages changed: `wiki/fork-free-build.md` (new), `wiki/window-switcher-research.md` (new), `wiki/index.md`, `wiki/state.md`.
- Verification: patch locations and line references checked against `HEAD` of `free`; build artifact checked (version, signature, update-block string).
- Notes: in-app confirmation of the Pro unlock and of ⌘` reaching Brave's other-Space window is still unverified. Upstream architecture ingest not done.
