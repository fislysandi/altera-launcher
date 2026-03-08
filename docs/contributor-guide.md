# Contributor Guide

This guide helps contributors move from first clone to first meaningful change quickly.

## 1) Understand the Product Model

Altera is built around one constraint:

- Core is small and stable.
- Features live in extensions.

Read first:

- `README.md`
- `docs/architecture.md`
- `docs/anti-hardcode-checklist.md`

## 2) Local Development Loop

Install dependency set:

```bash
OCICL_LOCAL_ONLY=1 ocicl install
```

Run launcher:

```bash
sbcl --script start.lisp
```

Run tests:

```bash
OCICL_LOCAL_ONLY=1 ocicl install && rove -r spec tests/main.lisp
```

## 3) Where to Put Changes

- `src/core/`:
  only contracts and runtime primitives (loader, registry, dispatcher, query).
- `src/extensions/api.lisp`:
  extension integration contracts (`define-extension`, `define-command`, `define-options-source`).
- `extensions/<name>/`:
  feature implementation.
- `docs/`:
  architecture, plans, checklists, contributor docs.

If your change introduces user-facing behavior, default to extension scope.

## 4) Typical Contribution Types

### Add a Command

1. Pick or create an extension under `extensions/`.
2. Register extension with `define-extension`.
3. Add command via `define-command`.
4. Ensure command metadata (`:title`, `:description`, optional `:tags`) is meaningful.
5. Add tests if behavior is non-trivial.

### Add Launcher Results

1. Register provider with `define-options-source`.
2. Return normalized option-like plists (id/title/subtitle/kind/command/args/icon when relevant).
3. Validate behavior via `list-launcher-options` from runtime.
4. Avoid UI-specific data shaping when a generic option field can express it.

### Change UI Behavior

1. Keep toolkit adapter thin.
2. Prefer command/keymap/options contracts over toolkit-embedded business logic.
3. Keep strings and labels centralized/configurable when possible.

## 5) Testing Strategy

Current tests are in `tests/` and focus on core and extension loading behavior.

- Add or update tests when changing contracts.
- For UI-oriented changes, at minimum ensure command and options contracts remain stable.

## 6) Documentation Strategy

When you change behavior, update docs in the same PR:

- public usage change -> `README.md`
- architecture/contract change -> `docs/architecture.md`
- extension loading/dependency change -> `docs/extensions-manifest.md`
- contributor workflow change -> `CONTRIBUTING.md` or this file

Add or update function docstrings for public APIs so REPL help stays useful.

Example:

```lisp
(documentation 'altera-launcher:bootstrap 'function)
```

## 7) Git Hygiene

- Keep commits focused and atomic.
- Do not mix unrelated refactors with feature changes.
- Preserve user or local environment files unless your PR explicitly targets them.

## 8) First Good Issues (Suggested)

- improve option ranking/scoring
- add extension metadata conventions
- add extension health/discovery command
- improve troubleshooting coverage and diagnostics docs
