#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"
env OCICL_LOCAL_ONLY=1 ocicl install >/dev/null
exec sbcl --script "$SCRIPT_DIR/start.lisp"
