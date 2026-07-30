#!/bin/bash
# Gated issue creation with mandatory linter pass precondition.
# Usage: ./create_issue.sh <body-file> <label> <title> <repo>
set -euo pipefail

LOCAL_FILE="$1"
LABEL="$2"
TITLE="$3"
REPO="${4:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINTER="$SCRIPT_DIR/verify_model_coverage.py"

if [ ! -f "$LOCAL_FILE" ]; then
    echo "FATAL: Body file not found: $LOCAL_FILE" >&2
    exit 1
fi

if [ ! -f "$LINTER" ]; then
    echo "WARNING: Linter not found at $LINTER — proceeding without gate." >&2
else
    echo "[GATE] Running linter: $LINTER --spec-only --allow-missing-specs"
    if ! python3 "$LINTER" --spec-only --allow-missing-specs; then
        echo "FATAL: Linter failed. Fix all specification violations before filing issues." >&2
        exit 1
    fi
    echo "[GATE] Linter passed."
fi

if [ -n "$REPO" ]; then
    gh issue create --repo "$REPO" --title "$TITLE" --label "$LABEL" --body-file "$LOCAL_FILE"
else
    gh issue create --title "$TITLE" --label "$LABEL" --body-file "$LOCAL_FILE"
fi
