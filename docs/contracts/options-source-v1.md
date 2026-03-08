# Options Source Contract v1

This document defines the launcher options-source contract used by extensions.

## Provider Signature

- Register providers using `define-options-source`.
- Provider function receives:
  - `query` (string)
  - optional `context` (plist or extension-defined shape)

Provider return value can be:

- one option item plist
- list of option item plists

## Normalized Item Shape

Each item is normalized into:

- `:id` (string, required)
- `:title` (string, required)
- `:subtitle` (string, optional, default `""`)
- `:kind` (`:command` or `:application`, optional default `:command`)
- `:icon` (string, optional)
- `:command` (string or NIL)
- `:args` (list, optional default `()`)
- `:source` (string, provider id)
- `:extension` (string, extension id)

## Validation Rules

An item is valid when:

- `:id` exists
- `:title` is a string
- `:kind` is `:application` OR
- `:kind` is `:command` and `:command` is string or NIL

Invalid items are dropped during collection.

## Filtering, Deduplication, Sorting

Runtime collection behavior:

- Query matching checks `:title` and `:subtitle` (case-insensitive contains).
- Dedupe uses normalized `:id`.
- Sort is stable by lowercase title, then id.

## Error Semantics

- `collect-option-items` returns only successful normalized items.
- `collect-option-report` returns:
  - `:items` normalized items
  - `:errors` list of provider failures, each with:
    - `:source`
    - `:extension`
    - `:error`

Use `collect-option-report` when diagnostics are needed.

## Authoring Example

```lisp
(define-options-source "example.source" (query)
  (declare (ignore query))
  (list :id "example.run"
        :title "Run Example"
        :subtitle "Example Extension"
        :kind :command
        :command "example.run"
        :args '()))
```
