# M1 Execution Plan (1-2 Weeks)

Goal: deliver a daily-driver launcher MVP that is fast, keyboard-first, and stable.

## Week 1 - Core Interaction Loop

## Day 1-2: Keyboard-first GUI behavior

- [ ] Remove dependency on `Prev/Next/Close` buttons for normal usage
- [ ] Add `Up`/`Down` row navigation in GTK window
- [ ] Add `Enter` to execute selected command
- [ ] Keep `Esc` close behavior reliable from both input and window
- [ ] Add tests for key behavior contract in integration suite

Exit criteria:
- You can launch, type, navigate, and execute without mouse usage.

## Day 3-4: Result list quality

- [ ] Replace plain text list blob with row-based widget list
- [ ] Add clear selected-state styling
- [ ] Show minimal metadata per row (source/tag/title)
- [ ] Keep search updates smooth while typing
- [ ] Add tests for selected index/state consistency

Exit criteria:
- Results look structured and selection is always visually obvious.

## Day 5: Command execution loop and feedback

- [ ] Execute selected result on `Enter`
- [ ] Add success/failure feedback in status rail
- [ ] Keep launcher open/close behavior configurable after execution
- [ ] Add error-safe guard so failed commands do not crash UI

Exit criteria:
- Command execution works from keyboard and errors stay contained.

## Week 2 - Visual Polish and Stability

## Day 6-7: Theme-to-GTK CSS bridge

- [ ] Map `ui-theme` tokens into GTK CSS rules
- [ ] Style search box, result rows, preview, status rail with consistent spacing
- [ ] Improve focus ring and contrast
- [ ] Verify both light and dark presets are legible

Exit criteria:
- UI reflects theme tokens consistently, with no raw default widget look.

## Day 8-9: State clarity and edge cases

- [ ] Add explicit empty/loading/no-preview states
- [ ] Handle zero results gracefully (`Enter` does nothing, no crash)
- [ ] Improve startup diagnostics for display/GTK/runtime checks
- [ ] Add quick troubleshooting messages for common failure modes

Exit criteria:
- No ambiguous states; user always knows what is happening.

## Day 10: Hardening and release checklist

- [ ] Run full test suite and fix regressions
- [ ] Add smoke checklist for launch path (`sbcl --script start.lisp`)
- [ ] Update `README.md` with non-REPL user flow
- [ ] Mark completed roadmap items and tag M1 checkpoint

Exit criteria:
- M1 is stable enough for daily use in your own workflow.

## Prioritized Backlog (if time remains)

- [ ] Add recency-based ranking in search results
- [ ] Add command aliases
- [ ] Add pinned commands/recent commands
- [ ] Add global hotkey extension spike

## M1 Definition of Done

- [ ] Launcher opens reliably from `start.lisp`
- [ ] Fully keyboard-driven interaction works end-to-end
- [ ] Visual hierarchy is clean and intentional
- [ ] Command execution feedback is clear and non-disruptive
- [ ] Critical tests pass and no crash-on-error path remains
