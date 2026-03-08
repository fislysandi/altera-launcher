# altera-launcher

Minimal, extension-first launcher written in Common Lisp.

`altera-launcher` keeps the core intentionally small and stable. Features live in extensions.

## Features

- Tiny core: extension loader, command registry, dispatcher, query, bootstrap
- Extension-first command model where each extension is its own Lisp project
- OCICL manager extension for dependency sync and extension dependency install
- UI theme extension with palette/typography/spacing/motion tokens
- UI renderer extension with layout hooks and launcher surface contract
- UI terminal extension with search box, result list, preview pane, and animated selection model
- App scanner extension for installed desktop applications
- UI GTK extension for a desktop launcher window
- Keymap engine extension with Vim default and Emacs optional profile
- Toolkit-agnostic options source API for cross-toolkit extension compatibility
- GTK launcher window behavior: undecorated, centered input, `Esc` closes
- Deterministic command lookup and dispatch
- Test coverage for core and extension loading

## Project Layout

- `src/core/` - minimal core modules
- `src/extensions/` - extension API only
- `extensions/<name>/` - extension projects (`.asd`, `src/`, optional tests)
- `extensions/extensions-manifest.lisp` - one-command extension/dependency setup manifest
- `templates/ocicl-extension-template/` - copyable OCICL-ready extension starter
- `start.lisp` - one-command bootstrap helper
- `tests/` - rove test suites
- `docs/architecture.md` - architecture and contracts
- `docs/anti-hardcode-checklist.md` - contribution checklist for futureproof changes
- `CONTRIBUTING.md` - contribution rules and PR checklist
- `docs/contributor-guide.md` - contributor onboarding workflow
- `docs/extension-authoring-guide.md` - extension implementation guide
- `docs/contracts/options-source-v1.md` - strict options-source item contract and diagnostics
- `docs/troubleshooting.md` - common setup/runtime issues and fixes
- `docs/hackability-improvements.md` - source-level improvement proposals for contributors
- `docs/pattern-adaptation-plan.md` - selected source patterns to adapt
- `docs/pattern-attribution.md` - attribution for adapted ideas

## Default User Config

On first bootstrap without explicit `:extension-paths`, Altera creates:

- `~/.config/altera-launcher/config.lisp`
- `~/.config/altera-launcher/extensions/` (default extension install directory)

Keymap defaults in `config.lisp`:

- `:keymap-profile "vim"` (default)
- `:keymap-overrides ()` for custom chord-to-action mappings

Extension loading controls in `config.lisp`:

- `:enabled-extensions ()` to allowlist extension system names
- `:disabled-extensions ()` to blocklist extension system names
- `:extensions-auto-reload nil` to reload extension state before each runtime call

If `:enabled-extensions` is non-empty, only listed extensions are loaded.
Entries in `:disabled-extensions` are always skipped.
When `:extensions-auto-reload` is `t`, launcher commands and option queries rebuild extension state automatically for rapid debugging.
When auto reload is `nil`, you can trigger reload manually with `extensions.reload`.

This keeps user-installed extensions separate from repo-local development extensions.

If you use this default user mode, copy extension projects you want from repository `extensions/` into `~/.config/altera-launcher/extensions/`.
For GUI mode, ensure `ui-gtk` is present there.

## One-Command Start

```bash
sbcl --script start.lisp
```

This script syncs OCICL dependencies, bootstraps runtime, and launches GUI automatically when `ui-gtk` is available.

## Quick Start

```bash
OCICL_LOCAL_ONLY=1 ocicl install
```

```lisp
(require :asdf)
(asdf:load-asd "./altera-launcher.asd")
(asdf:load-system :altera-launcher)
```

```lisp
(defparameter *runtime* (altera-launcher:bootstrap))
(altera-launcher:run-command *runtime* "extensions.list")
(altera-launcher:run-command *runtime* "extensions.index")
(altera-launcher:run-command *runtime* "extensions.contract.validate")
(altera-launcher:run-command *runtime* "extensions.enable" "ui-gtk")
(altera-launcher:run-command *runtime* "extensions.disable" "ui-terminal")
(altera-launcher:run-command *runtime* "ui.theme.presets")
(altera-launcher:run-command *runtime* "ui.renderer.contract")
(altera-launcher:run-command *runtime* "ui.terminal.search" "open")
(altera-launcher:run-command *runtime* "ui.gui.launch")
```

## Running Tests

```bash
OCICL_LOCAL_ONLY=1 ocicl install && rove -r spec tests/main.lisp
```

Or via ASDF:

```lisp
(asdf:load-asd "./altera-launcher.asd")
(asdf:test-system :altera-launcher/tests)
```

## Build Artifacts

Build a platform artifact on the current machine:

```bash
OCICL_LOCAL_ONLY=1 ocicl install
sbcl --script scripts/build-release-image.lisp
```

Override output name/path:

```bash
ALTERA_BUILD_OUTPUT="$(pwd)/dist/altera-launcher-custom" sbcl --script scripts/build-release-image.lisp
```

CI matrix build and artifact upload are defined in:

- `.github/workflows/build-matrix.yml`

Windows CI uses Scoop to install SBCL and bootstrap OCICL before build.

## Release Automation

Use GitHub Actions workflow dispatch to create a release and attach Linux/macOS/Windows artifacts:

- `.github/workflows/release.yml`

Required workflow inputs:

- `tag` (for example `v0.1.0`)
- `name` (release title)
- `prerelease` (`true` or `false`)

## Writing Extensions

Create a project under `extensions/` with its own `.asd` and source files.

Example structure:

```text
extensions/my-extension/
  my-extension.asd
  src/packages.lisp
  src/extension.lisp
```

Inside your extension source, use the extension API:

```lisp
(in-package #:altera-launcher.extensions.my-extension)

(define-extension ("my-extension" :version "0.1.0" :description "Example")
  (define-command "my-command"
    (lambda (&rest args) (declare (ignore args)) "ok")
    :title "My Command"
    :description "Example command"))
```

The core should not change when adding new feature behavior.

## Toolkit-Agnostic Options API

Extensions can define launcher option providers once and keep compatibility across GTK, terminal, and future UI toolkits.

```lisp
(define-options-source "my-extension.options" (query)
  (declare (ignore query))
  (list (list :id "my.action"
              :title "Run My Action"
              :subtitle "My Extension"
              :kind :command
              :command "my.action")))
```

Runtime consumers can query normalized options through:

```lisp
(altera-launcher:list-launcher-options *runtime* :query "sync")
```

## Declaring Themes in Lisp

Each theme lives in its own folder under either user config or bundled themes:

- `~/.config/altera-launcher/themes/<theme-name>/theme.lisp` (user override path)

- `extensions/ui-theme/themes/<theme-name>/theme.lisp`

If a theme name exists in both locations, the user config theme is loaded first and wins.

Declare the theme in that file:

```lisp
(in-package #:altera-launcher.extensions.ui-theme)

(define-theme "my-theme"
  :palette (:background "#111827" :foreground "#f9fafb" :primary "#22c55e" :accent "#f59e0b")
  :typography (:ui "Inter" :display "Space Grotesk" :mono "JetBrains Mono")
  :spacing (:base 4 :scale (:1 4 :2 8 :3 12 :4 16))
  :motion (:duration-fast 90 :duration-medium 160 :duration-slow 280))
```

Then select theme through config:

```lisp
(:theme-preset "my-theme")
```

## Manifest-Based Setup

Use the OCICL manager extension to discover and install dependencies declared by manifest:

```lisp
;; list extension projects from manifest
(altera-launcher:run-command *runtime* "extensions.manifest.list")

;; dry-run install
(altera-launcher:run-command *runtime* "extensions.manifest.install"
                             "extensions/extensions-manifest.lisp"
                             t)
```

## OCICL Extension Template

Use `templates/ocicl-extension-template/` as a starter for community extensions.

1. Copy the template to `extensions/<your-name>/`
2. Rename system/package/command identifiers
3. Add extension entry to `extensions/extensions-manifest.lisp`
4. Run `OCICL_LOCAL_ONLY=1 ocicl install`

## Contributing

Start with:

- `CONTRIBUTING.md`
- `docs/contributor-guide.md`
- `docs/extension-authoring-guide.md`
- `docs/troubleshooting.md`

## License

GNU General Public License v3.0 or later (GPL-3.0-or-later).
