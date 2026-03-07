# Extensions Manifest

`extensions/extensions-manifest.lisp` is the workspace manifest for extension projects and OCICL dependencies.

## Purpose

- Keep extension project discovery explicit.
- Enable one-command dependency setup through `ocicl-manager`.
- Document which OCICL projects each extension requires.

## Format

The manifest is a Lisp plist:

```lisp
(:version "1"
 :extensions
 ((:name "ui-theme"
   :system "ui-theme"
   :asd "extensions/ui-theme/ui-theme.asd"
   :ocicl-projects ())
  ...))
```

Each extension entry supports:

- `:name` - human-readable extension name
- `:system` - ASDF system name
- `:asd` - path to the system definition
- `:ocicl-projects` - list of OCICL project names required by extension

## Commands

With runtime bootstrapped:

- `extensions.manifest.list` - list extension names from manifest
- `extensions.manifest.install [path] [dry-run]` - install OCICL projects declared by manifest

## Notes

- Keep `ocicl.csv` committed for reproducible dependency resolution.
- Do not commit `ocicl/` vendor directory.
- Template projects (for example `templates/ocicl-extension-template/`) are not auto-loaded; copy them under `extensions/` when you want to activate them.
