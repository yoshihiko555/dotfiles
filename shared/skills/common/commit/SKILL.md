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
4. If every change in the specified paths belongs to the current conversation, use `git commit --only -m "<message>" -- <paths>`. First run `git add -- <path>` for each untracked file being included. If the sandbox blocks the required Git operation, request approval for that operation.

Stage only the relevant files and create the commit. Do nothing else in this skill.
