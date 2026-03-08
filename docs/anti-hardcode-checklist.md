# Anti-Hardcode Checklist

Use this checklist before merging launcher features.

## Goal

Keep Altera easy to change on the fly by avoiding hardcoded product behavior in toolkit code.

## Checklist

- [ ] New user-facing options come from extension option sources (`define-options-source`) instead of toolkit-local static lists.
- [ ] Toolkit adapters consume normalized option items (`list-launcher-options`) rather than extension internals.
- [ ] Keyboard behavior resolves through keymap engine actions, not hardcoded key branches in UI code.
- [ ] New UI labels/messages are either configurable or centralized in one adapter boundary (not duplicated across files).
- [ ] Feature behavior is command-driven (`run-command`) and not directly embedded in render widgets.
- [ ] New defaults are documented in config contracts and can be overridden by users.
- [ ] Changes preserve toolkit portability (GTK today, other toolkits tomorrow).
- [ ] Integration tests cover new contract behavior (options shape, key action mapping, command dispatch path).

## Red Flags

- Hardcoded app lists in toolkit files.
- Toolkit-specific branching for business logic decisions.
- Multiple competing sources of truth for option items.
- Keybindings implemented outside keymap engine without clear reason.

## Rule of Thumb

If a product behavior would need editing in more than one toolkit file, it likely belongs in an extension contract, command, or config layer.
