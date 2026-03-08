# Altera Launcher Roadmap

General project goals and progress checklist.

## Core Architecture

- [x] Keep core minimal (loader, registry, dispatcher, query, bootstrap)
- [x] Use extension-first design for all feature behavior
- [x] Support extension projects as independent ASDF systems
- [x] Add duplicate/unknown command error conditions
- [x] Adopt change-on-the-fly north star (config and extension contracts first)
- [ ] Remove remaining toolkit-level hardcoded labels/strings from UI adapters
- [ ] Add extension API versioning and compatibility policy
- [x] Add toolkit-agnostic options source API (`define-options-source`)
- [ ] Add safe extension sandbox boundaries and timeout controls

## Configuration & Runtime

- [x] Create default user config at `~/.config/altera-launcher/config.lisp`
- [x] Use default user extension directory `~/.config/altera-launcher/extensions/`
- [x] Support custom extension path patterns from config
- [x] Provide one-command startup (`sbcl --script start.lisp`)
- [ ] Add config schema validation and helpful migration warnings
- [ ] Add profile support (`work`, `personal`, `minimal`)

## Extension Ecosystem

- [x] Provide OCICL manager extension for dependency install/sync
- [x] Support manifest-based extension dependency setup
- [x] Add copyable OCICL extension template
- [x] Add first options-source extension target: OCICL manager
- [ ] Add extension metadata conventions (name, version, author, homepage)
- [ ] Add extension discovery/index command with health status
- [ ] Add extension enable/disable commands without deleting files
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
- [ ] Add user theme override file support
- [ ] Add layout presets and per-layout options
- [ ] Add reduced-motion mode and accessibility presets

## Reliability, Testing, and Observability

- [x] Add core + integration tests with rove
- [x] Add GUI preflight command (`ui.gui.self-test`)
- [x] Validate startup path without REPL dependency
- [ ] Add startup diagnostics log file in user config dir
- [ ] Add extension load timing and failure diagnostics
- [ ] Add snapshot tests for UI state contracts
- [ ] Add anti-hardcode review checklist to CI/release gates
- [ ] Add CI workflow for load/test/lint checks

## Packaging & Distribution

- [ ] Add executable launcher command wrapper for desktop usage
- [ ] Add desktop entry (`.desktop`) and icon integration
- [ ] Add release process and versioning strategy
- [ ] Add install/uninstall docs for Linux distributions
- [ ] Evaluate Windows/macOS portability strategy

## Documentation & Developer Experience

- [x] Maintain architecture and manifest docs
- [x] Provide extension template docs
- [ ] Add end-user quickstart focused on non-REPL usage
- [ ] Add contributor guide for extension authors
- [ ] Add troubleshooting guide for GTK/display/runtime issues
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
