# Pattern Adaptation Plan

This document identifies source patterns from local `stumpwm/` to adapt into `altera-launcher` while keeping this project independent and minimal.

## Selected Patterns

1. Package boundary discipline
   - Source: `stumpwm/package.lisp`
   - Why: Clean package boundaries and explicit exports make extension APIs safer.
   - Adaptation: Separate core packages, extension API package, and top-level public package.

2. Command registry via hash table
   - Source: `stumpwm/command.lisp` (`*command-hash*`, command metadata)
   - Why: Fast command lookup and clear command metadata model.
   - Adaptation: Keep a smaller registry focused on command identity, handler, and extension metadata.

3. Module discovery and loading paths
   - Source: `stumpwm/module.lisp` (`build-load-path`, `list-modules`, `load-module`)
   - Why: Extension-first launcher needs deterministic extension discovery.
   - Adaptation: Pattern-based extension file discovery and load-time registration.

4. Explicit conditions for operational failures
   - Source: `stumpwm/command.lisp` and module-loading error paths
   - Why: Extension systems need clear error boundaries.
   - Adaptation: dedicated conditions for duplicate registration and unknown command dispatch.

## Boundaries

- Do not copy full modules from `stumpwm`.
- Do not import window manager behavior.
- Do not carry over StumpWM-specific interactive argument parsing.
- Keep adaptations structural and conceptual.
