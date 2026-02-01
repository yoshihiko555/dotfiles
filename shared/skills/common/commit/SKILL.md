---
name: commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit (context-aware version)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the conversation context and the above changes, create a single git commit.

**Important rules:**

1. Only stage and commit files that were **directly discussed or modified during the current conversation**.
2. Do NOT include unrelated changes that happen to exist in the working directory.
3. If you're unsure which files are relevant, ask the user before proceeding.
4. Use `git add <specific-file>` for each relevant file individually, rather than `git add .` or `git add -A`.

You have the capability to call multiple tools in a single response. Stage only the relevant files and create the commit using a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
