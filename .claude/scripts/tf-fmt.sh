#!/bin/sh
# Format the .tf file Claude just wrote. Never blocks — always exits 0.
command -v jq >/dev/null 2>&1 && command -v terraform >/dev/null 2>&1 || exit 0
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
case "$f" in *.tf) [ -f "$f" ] && terraform fmt "$f" >/dev/null 2>&1 ;; esac
exit 0
