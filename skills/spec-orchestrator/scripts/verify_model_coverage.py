#!/usr/bin/env python3
# Copyright Gint Atkinson, gint.atkinson@gmail.com

import sys
import os

def sanitize_github_token_env():
    """
    Sanitize environment by removing dummy or placeholder GITHUB_TOKEN and GH_TOKEN
    values that interfere with git/gh terminal operations.
    """
    dummy_keywords = ("antigravity", "dummy", "placeholder", "invalid", "mock")
    for var in ("GITHUB_TOKEN", "GH_TOKEN"):
        val = os.environ.get(var)
        if val and any(kw in val.lower() for kw in dummy_keywords):
            os.environ.pop(var, None)

sanitize_github_token_env()

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "parity_auditor", "src")))

from parity_auditor.cli import main

if __name__ == "__main__":
    sanitize_github_token_env()
    main()

