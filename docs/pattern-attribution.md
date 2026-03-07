# Pattern Attribution

`altera-launcher` references architectural ideas from the local `stumpwm/` checkout in this repository.

## Attribution

- Project: StumpWM
- Local source path: `stumpwm/`
- Relevant files reviewed:
  - `stumpwm/package.lisp`
  - `stumpwm/command.lisp`
  - `stumpwm/module.lisp`

## What Was Reused

- Conceptual patterns only:
  - package and export discipline
  - command registration shape
  - module discovery strategy
  - explicit condition-based errors

## What Was Not Reused

- Window manager behavior and runtime model
- StumpWM command argument type system
- StumpWM keybinding or X11 integration code

## Notes

No wholesale copy was performed. `altera-launcher` keeps an independent codebase and API contract tailored to a launcher architecture.
