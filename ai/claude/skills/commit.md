---
description: Creates a signed Git commit using Claude's GPG key.
argument-hint: [commit-message]
allowed-tools: Bash(git commit:*)
---

!git commit -S -m "$ARGUMENTS"

> Thanks,
> [coygeek](https://github.com/anthropics/claude-code/issues/7711#issuecomment-3300776605)!
