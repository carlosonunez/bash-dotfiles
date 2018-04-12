#!/usr/bin/env bash
DEFAULT_ALLOWED_BRANCHES="master|dev"
allowed_branches=$(cat "$(git rev-parse --show-toplevel)/allowed_branches")
allowed_branches="${allowed_branches:-DEFAULT_ALLOWED_BRANCHES}"
allowed_branches_regex="$(echo "$allowed_branches" | tr "\\n" '|' | sed 's/.$//')"
$(git rev-parse --abbrev-ref HEAD | grep -Eqv "$allowed_branches_regex")
