# Altera Extension Template (OCICL-ready)

Use this starter to create your own `altera-launcher` extension project.

## What You Get

- ASDF system scaffold
- package and extension source files
- a sample command (`template.health`)
- OCICL-compatible workflow

## Use This Template

1. Copy `templates/ocicl-extension-template/` to `extensions/<your-extension-name>/`
2. Rename `altera-extension-template.asd` and system name to your extension name
3. Update package names in `src/packages.lisp` and `src/extension.lisp`
4. Rename extension id and command names from `template.*`
5. Add your extension entry to `extensions/extensions-manifest.lisp`

## Dependency Workflow

```bash
OCICL_LOCAL_ONLY=1 ocicl install
```

## Load Check

```lisp
(require :asdf)
(asdf:load-asd "./altera-launcher.asd")
(asdf:load-system :altera-launcher)
(defparameter *runtime* (altera-launcher:bootstrap))
(altera-launcher:run-command *runtime* "template.health")
```
