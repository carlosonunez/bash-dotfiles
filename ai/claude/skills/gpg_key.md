---
description: Displays a project's GPG key.
allowed-tools: Bash(gpg:*)
argument-hints: [project-key-name]
---

!gpg --list-keys "$ARGUMENTS"
