# Architecture

## Design Goal

`altera-launcher` keeps the core minimal and stable while delivering user-facing behavior through extensions.

## Minimal Core Boundaries

Core modules only include:

- `src/core/extension-loader.lisp` - extension discovery and extension registration
- `src/core/command-registry.lisp` - command identity and lookup
- `src/core/dispatcher.lisp` - command execution with explicit unknown-command errors
- `src/core/query.lisp` - read-only command metadata querying
- `src/main.lisp` - bootstrap wiring

Core does not contain business features like app launching, file indexing, clipboard history, or workflow automation.
Visual style and theming are extension concerns, so UI identity can evolve without changing core internals.

## Extension Contract

Extensions use `src/extensions/api.lisp`:

- `define-extension` registers extension metadata
- `define-command` registers command handlers and metadata
- `define-options-source` registers toolkit-agnostic option providers consumed by any UI adapter

Extensions are independent Lisp projects under `extensions/<name>/` and are loaded during bootstrap from `.asd` path patterns.
The workspace manifest `extensions/extensions-manifest.lisp` declares extension metadata and OCICL dependency projects for one-command setup.
Default user bootstrap writes config at `~/.config/altera-launcher/config.lisp` and extension directory `~/.config/altera-launcher/extensions/`.

## Runtime Flow

1. Bootstrap creates a registry and extension loader.
2. Bootstrap discovers extension `.asd` files and resolves system names.
3. Bootstrap registers all discovered extension systems with ASDF.
4. Bootstrap loads each extension system with active extension context.
5. Extension code registers extension metadata, commands, and option sources.
6. Runtime dispatches commands by name.
7. Runtime can collect launcher options through `list-launcher-options` independent of toolkit.
8. Query surfaces expose command and extension metadata.

## UI Strategy

- `ui-theme` extension owns visual tokens (palette, typography, spacing, motion).
- `ui-renderer` extension owns renderer surface contract and layout hooks.
- `ui-terminal` extension composes theme + renderer contracts into a terminal launcher state model.
- `ui-gtk` extension renders a desktop GUI window and consumes terminal/theme/renderer state contracts.
- Core stays UI-agnostic; future frontends can consume these contracts without changing core modules.

## Error Model

- Duplicate command registration -> `duplicate-command-error`
- Duplicate extension registration -> `duplicate-extension-error`
- Missing command dispatch -> `unknown-command-error`

This keeps failures explicit and easier to debug in REPL-driven workflows.
