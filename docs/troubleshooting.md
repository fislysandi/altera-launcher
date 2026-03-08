# Troubleshooting

Common contributor issues and fast fixes.

## OCICL Dependencies Not Found

Symptoms:

- systems fail to load
- missing package/library errors

Fix:

```bash
OCICL_LOCAL_ONLY=1 ocicl install
```

Then reload with ASDF or rerun `sbcl --script start.lisp`.

## Extension Not Loaded

Symptoms:

- command not found
- extension behavior missing

Checks:

1. Ensure extension has a valid `.asd` file under a discovered path pattern.
2. Verify extension path patterns in `~/.config/altera-launcher/config.lisp`.
3. Confirm the extension is listed in `extensions/extensions-manifest.lisp` when using manifest workflows.

## Unknown Command at Runtime

Symptoms:

- `unknown-command-error`

Checks:

1. Confirm command id spelling and case-insensitive normalization.
2. Confirm extension registration code executes during system load.
3. Verify command is defined inside `define-extension` scope.

## Duplicate Registration Errors

Symptoms:

- `duplicate-command-error`
- `duplicate-extension-error`

Checks:

1. Ensure command names are globally unique.
2. Ensure extension names are globally unique.
3. Avoid loading the same extension system multiple times via overlapping path patterns.

## GTK Window Does Not Launch

Symptoms:

- bootstrap completes but no window

Checks:

1. Verify display variables exist (`DISPLAY` or `WAYLAND_DISPLAY`).
2. Run preflight from startup output (`ui.gui.self-test`).
3. Ensure `ui-gtk` extension is available in active extension paths.
4. Ensure `ALTERA_NO_GUI` is not set to `1`.

## No Options in Launcher List

Symptoms:

- launcher opens but results are empty

Checks:

1. Verify at least one options source is registered by loaded extensions.
2. Check that provider output includes valid option item fields.
3. Confirm query filtering is not too restrictive.

## Tests Failing Locally

Run full test command:

```bash
OCICL_LOCAL_ONLY=1 ocicl install && rove -r spec tests/main.lisp
```

If failures persist:

- verify extension loader changes against integration tests
- ensure modified command names/metadata match test expectations
- clear stale REPL state and rerun in a fresh SBCL process
