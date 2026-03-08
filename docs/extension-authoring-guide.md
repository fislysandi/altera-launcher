# Extension Authoring Guide

Use this guide when building new Altera features.

## Why Extensions First

Extensions keep product behavior decoupled from core runtime internals.

Default rule:

- new user-facing capability -> extension
- core change only when extension contracts cannot express the requirement

## Extension Skeleton

Create a project under `extensions/`:

```text
extensions/my-extension/
  my-extension.asd
  src/packages.lisp
  src/extension.lisp
```

You can copy:

- `templates/ocicl-extension-template/`

## Minimal Extension Example

```lisp
(in-package #:altera-launcher.extensions.my-extension)

(define-extension ("my-extension" :version "0.1.0" :description "Example")
  (define-command "my-extension.ping"
    (lambda (&rest args) (declare (ignore args)) "pong")
    :title "Ping"
    :description "Simple extension command"))
```

## Registering Option Sources

Use `define-options-source` to expose launcher items in a toolkit-agnostic way.

```lisp
(define-options-source "my-extension.options" (query context)
  (declare (ignore query context))
  (list (list :id "my-extension.ping"
              :title "Ping"
              :subtitle "My Extension"
              :kind :command
              :command "my-extension.ping")))
```

Prefer this over toolkit-specific item lists.

## Option Item Shape Guidance

Recommended fields:

- `:id` string, unique and stable
- `:title` string, user-facing
- `:subtitle` string, source/context
- `:kind` typically `:command` or `:application`
- `:command` command identifier for command items
- `:args` list of arguments for dispatcher
- `:icon` icon hint/path when relevant

For strict rules and diagnostics behavior, see:

- `docs/contracts/options-source-v1.md`

## Manifest Integration

Add extension metadata to:

- `extensions/extensions-manifest.lisp`

Include:

- system name
- `.asd` path
- required OCICL projects

Then validate with:

- `extensions.manifest.list`
- `extensions.manifest.install`

See `docs/extensions-manifest.md` for details.

## Key Architectural Checks

Before merging, confirm:

- behavior is command-driven, not widget-driven
- no hardcoded product lists inside toolkit files
- options provider works with `list-launcher-options`
- docs and docstrings are updated

Use `docs/anti-hardcode-checklist.md` as your final gate.
