# Hackability and Flexibility Improvements

This document lists source-level changes that would improve contributor velocity and reduce future rewrite cost.

## High-Leverage Changes

## 1) Add Extension Lifecycle Commands

Add command contracts for:

- extension enable/disable without file deletion
- extension reload (single extension and all)
- extension health report (load status, command count, options-source count)

Why it helps:

- contributors can iterate without restarting full runtime
- extension debugging becomes explicit and scriptable

## 2) Introduce Config Schema Validation

Add a config validation layer at bootstrap:

- key presence/type checks
- enum checks for profile/theme values
- migration warnings for deprecated keys

Why it helps:

- prevents silent misconfiguration
- makes config evolution safer for contributors

## 3) Define Extension API Version Contract

Add API version metadata in extension registration and manifest.

Suggested shape:

- runtime API version constant
- extension declares minimum/maximum compatible API versions
- loader emits actionable compatibility errors

Why it helps:

- enables ecosystem growth without brittle breakage

## 4) Add Structured Diagnostics

Add diagnostics surface for startup and extension load:

- per-extension load timing
- captured load errors with extension id
- optional diagnostics log file under user config dir

Why it helps:

- reduces time to isolate failures
- improves maintainer support quality

## 5) Promote Option Item Contract to Shared Spec

Centralize option-item schema constants and validators:

- required and optional fields
- kind-specific constraints
- helper constructors for common item types

Why it helps:

- reduces subtle source/provider drift
- keeps GTK and future toolkits interoperable

## 6) Add Ranking Pipeline Hooks

Split option collection into stages:

- source collection
- normalization
- scoring/ranking
- post-process (dedupe/grouping)

Why it helps:

- contributors can improve search quality without rewriting providers
- makes experimentation isolated and reversible

## 7) Make GTK Adapter More Contract-Driven

Reduce GTK-local constants by moving them to config/theme/layout contracts:

- labels and empty-state strings
- key hint text templates
- list limits and spacing defaults

Why it helps:

- less toolkit hardcoding
- easier to add alternate frontends

## 8) Expand Test Coverage Around Contracts

Add tests for:

- options-source validation edge cases
- extension load order and duplicate path patterns
- config schema and migration behavior
- keymap override parsing matrix

Why it helps:

- contributors can refactor with confidence
- regression cost drops as feature surface grows

## Suggested Order

1. config schema validation
2. structured diagnostics
3. extension lifecycle commands
4. extension API version contract
5. ranking pipeline hooks
6. GTK adapter contract extraction
7. expanded contract tests

This order improves safety and debuggability first, then accelerates feature experimentation.
