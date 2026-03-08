# Altera Launcher Roadmap

General project goals and progress checklist.

## Priority Lanes

Use this as the contributor pick list.

### Now (highest leverage)

- [x] Harden config/manifest parsing (`*read-eval* nil` + schema checks)
- [x] Centralize launcher config path/read helpers into shared core module
- [x] Replace `/bin/sh -lc` app launch path with argv-safe execution
- [x] Extract shared desktop app catalog module used by `ui-terminal` and `app-scanner`
- [x] Surface options-source provider errors in diagnostics (no silent swallowing)
- [ ] Add config schema validation and helpful migration warnings
- [ ] Add startup diagnostics log file in user config dir
- [ ] Add extension load timing and failure diagnostics
- [x] Add extension discovery/index command with health status
- [x] Add extension enable/disable commands without deleting files
- [x] Add config option for extension auto-reload during debugging
- [ ] Add extension hot-reload command
- [ ] Promote launcher option item schema into shared contract constants and validators
- [ ] Split option processing into explicit stages (collect -> normalize -> rank -> dedupe/group)

### Next (polish and quality)

- [ ] Upgrade fuzzy search quality and scoring strategy
- [ ] Add recency/frequency ranking
- [ ] Define cross-platform support baseline (Linux, macOS, Windows)
- [ ] Move remaining GTK adapter labels/hints/defaults into config/theme/layout contracts
- [ ] Add polished loading/empty/error visual states
- [ ] Add integration tests for option schema validation and provider edge cases
- [ ] Add config migration tests for deprecated/renamed keys
- [ ] Add keymap override parsing matrix tests
- [ ] Add anti-hardcode review checklist to CI/release gates

### Later (ecosystem and distribution)

- [ ] Add extension API versioning and compatibility policy
- [ ] Add safe extension sandbox boundaries and timeout controls
- [ ] Add extension metadata conventions (name, version, author, homepage)
- [ ] Add CI workflow for load/test/lint checks
- [ ] Add executable launcher command wrapper for desktop usage
- [ ] Add desktop entry (`.desktop`) and icon integration
- [ ] Add release process and versioning strategy
- [ ] Add install/uninstall docs for Linux distributions
- [x] Add scripts to build distributable binaries for Linux/macOS/Windows
- [x] Add GitHub Actions matrix workflow to build all three platforms in parallel
- [x] Add workflow_dispatch release workflow that publishes cross-platform artifacts

## Core Architecture

- [x] Keep core minimal (loader, registry, dispatcher, query, bootstrap)
- [x] Use extension-first design for all feature behavior
- [x] Support extension projects as independent ASDF systems
- [x] Add duplicate/unknown command error conditions
- [x] Adopt change-on-the-fly north star (config and extension contracts first)
- [ ] Remove remaining toolkit-level hardcoded labels/strings from UI adapters
- [ ] Add extension API versioning and compatibility policy
- [x] Add toolkit-agnostic options source API (`define-options-source`)
- [ ] Promote launcher option item schema into shared contract constants and validators
- [ ] Split option processing into explicit stages (collect -> normalize -> rank -> dedupe/group)
- [ ] Add safe extension sandbox boundaries and timeout controls

## Configuration & Runtime

- [x] Create default user config at `~/.config/altera-launcher/config.lisp`
- [x] Use default user extension directory `~/.config/altera-launcher/extensions/`
- [x] Support custom extension path patterns from config
- [x] Provide one-command startup (`sbcl --script start.lisp`)
- [x] Harden config/manifest parsing (`*read-eval* nil` + schema checks)
- [ ] Add config schema validation and helpful migration warnings
- [ ] Add profile support (`work`, `personal`, `minimal`)

## Extension Ecosystem

- [x] Provide OCICL manager extension for dependency install/sync
- [x] Support manifest-based extension dependency setup
- [x] Add copyable OCICL extension template
- [x] Add first options-source extension target: OCICL manager
- [x] Add extension metadata conventions (name, version, author, homepage)
- [x] Add extension contract validator command (`extensions.contract.validate`)
- [x] Add extension discovery/index command with health status
- [x] Add extension enable/disable commands without deleting files
- [ ] Add extension hot-reload command

## UI Platform

- [x] Implement terminal UI state contract (`ui-terminal`)
- [x] Implement GTK GUI launcher extension (`ui-gtk`)
- [x] Make launcher window undecorated
- [x] Center input area in launcher window
- [x] Close launcher with `Esc`
- [x] Implement full keyboard navigation (`Up/Down/Enter`) without button dependency
- [x] Replace text blob list with proper result row widgets
- [x] Add GTK CSS bridge from `ui-theme` tokens
- [ ] Add polished loading/empty/error visual states
- [ ] Move remaining GTK adapter labels/hints/defaults into config/theme/layout contracts

## Search & Command UX

- [x] Support basic search/filter flow
- [ ] Upgrade fuzzy search quality and scoring strategy
- [ ] Add recency/frequency ranking
- [ ] Add aliases and command shortcuts
- [ ] Add command categories and source labels
- [ ] Add action preview details and quick actions

## Theming & Customization

- [x] Define theme token extension (`ui-theme`)
- [x] Define renderer contract extension (`ui-renderer`)
- [ ] Add multiple curated premium presets
- [x] Add user theme override file support
- [ ] Add layout presets and per-layout options
- [ ] Add reduced-motion mode and accessibility presets

## Reliability, Testing, and Observability

- [x] Add core + integration tests with rove
- [x] Add GUI preflight command (`ui.gui.self-test`)
- [x] Validate startup path without REPL dependency
- [ ] Add startup diagnostics log file in user config dir
- [ ] Add extension load timing and failure diagnostics
- [x] Surface options-source provider errors in diagnostics (no silent swallowing)
- [ ] Add snapshot tests for UI state contracts
- [ ] Add integration tests for option schema validation and provider edge cases
- [ ] Add config migration tests for deprecated/renamed keys
- [x] Add keymap override parsing matrix tests
- [ ] Add anti-hardcode review checklist to CI/release gates
- [ ] Add CI workflow for load/test/lint checks
- [x] Add CI artifacts upload for Linux/macOS/Windows build outputs

## Packaging & Distribution

- [ ] Add executable launcher command wrapper for desktop usage
- [ ] Add desktop entry (`.desktop`) and icon integration
- [ ] Add release process and versioning strategy
- [ ] Add install/uninstall docs for Linux distributions
- [ ] Make runtime and packaging fully cross-platform (Linux, macOS, Windows)
- [x] Add one-command build script that compiles launcher for all three platforms

## Documentation & Developer Experience

- [x] Maintain architecture and manifest docs
- [x] Provide extension template docs
- [ ] Add end-user quickstart focused on non-REPL usage
- [x] Add contributor guide for extension authors
- [x] Add troubleshooting guide for GTK/display/runtime issues
- [ ] Add roadmap progress updates by milestone

## Milestones

- [ ] **M1: Daily Driver MVP**
  - Stable GUI launch path
  - Keyboard-first command selection
  - Solid search and execution loop

- [ ] **M2: Polished Experience**
  - Theme-quality visuals
  - Smooth transitions and better preview UI
  - Better ranking and history

- [ ] **M3: Ecosystem Ready**
  - Mature extension tooling
  - Better docs and template ecosystem
  - Packaging for wider adoption

## Execution Plan Link

- [x] M1 detailed plan: `docs/m1-execution-plan.md`
- [x] Hackability/flexibility plan: `docs/hackability-improvements.md`
