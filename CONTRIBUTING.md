# Contributing to altera-launcher

Thanks for your interest in contributing.

This project is intentionally extension-first: keep the core minimal and put feature behavior in extensions.

## Start Here

1. Read `README.md` for quick setup and project layout.
2. Read `docs/architecture.md` for core boundaries and runtime flow.
3. Read `docs/anti-hardcode-checklist.md` before implementing feature changes.
4. Use `docs/contributor-guide.md` for day-to-day contribution workflow.

## Development Setup

Prerequisites:

- SBCL
- ASDF
- OCICL
- Rove
- GTK runtime/dev packages (only if you work on `ui-gtk`)

Install dependencies:

```bash
OCICL_LOCAL_ONLY=1 ocicl install
```

Run launcher bootstrap:

```bash
sbcl --script start.lisp
```

Run tests:

```bash
OCICL_LOCAL_ONLY=1 ocicl install && rove -r spec tests/main.lisp
```

## Contribution Rules

- Keep user-facing feature logic out of core modules (`src/core/`).
- Prefer `define-options-source` + `list-launcher-options` over toolkit-local static lists.
- Route behavior through commands and dispatch (`run-command`) instead of direct UI-side business logic.
- Keep changes configurable via `~/.config/altera-launcher/config.lisp` where possible.
- Maintain toolkit portability (GTK today, other toolkits later).

## Extension Contributions

For new features, start with an extension unless there is a clear core contract gap.

- Follow `docs/extension-authoring-guide.md`.
- Use `templates/ocicl-extension-template/` as the baseline.
- Register extension metadata in `extensions/extensions-manifest.lisp`.

## Documentation Requirements

- Update docs in the same PR when behavior/contracts change.
- Add docstrings to new public Lisp functions so REPL `documentation` output stays useful.
- If you add commands/options, document identifiers and expected item shape.
- Prefer short imperative docstrings in code (for example, "Return ...", "Set ...", "Load ...").

## Pull Request Checklist

- [ ] Tests pass locally.
- [ ] New behavior is extension-driven and follows anti-hardcode checklist.
- [ ] Docs are updated (`README.md`, `docs/*`, or both as needed).
- [ ] No unrelated file changes are mixed into the PR.

## Need Help?

- Troubleshooting: `docs/troubleshooting.md`
- Architecture and boundaries: `docs/architecture.md`
- Manifest behavior: `docs/extensions-manifest.md`
