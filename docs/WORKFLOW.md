# Development Workflow

End-to-end guide: from task to production.

---

## Overview

```
Issue / Task
    │
    ▼
 /spec ──── Clarify requirements ──── docs/specs/YYYY-MM-DD-<slug>.md
    │
    ▼
 /plan ──── Explore codebase ──── EnterPlanMode ──── User Approval
    │
    ▼
 Implement ──── Write code per docs/STANDARDS.md
    │
    ▼
 /test ──── pytest + mypy + ruff ──── Fix failures
    │
    ▼
 /commit ──── Conventional commit ──── Safety scan
    │
    ▼
 /pr ──── Check CI green ──── gh pr create ──── Link issues
    │
    ▼
 PR Review ──── /review ──── Address comments
    │
    ▼
 Merge ──── squash into develop / merge commit into main
    │
    ▼
 /deploy ──── Confirm ──── Monitor ──── Verify /health
    │
    ▼
 Production ✓
```

---

## Step 1: Spec (`/spec`)

**When**: A new task, issue, or feature request arrives.

**What you produce**: `docs/specs/YYYY-MM-DD-<slug>.md`

**Contents**:
- Problem statement and motivation
- Acceptance criteria (checkbox list)
- Technical decisions and trade-offs
- Dependencies (external services, new packages)
- Complexity estimate and risks

**Rule**: Never plan or implement before the spec is approved by the user.

---

## Step 2: Plan (`/plan`)

**When**: Spec is approved.

**What you do**:
1. Explore the existing codebase (Glob, Grep, Read)
2. List every file to create or modify
3. Define the implementation sequence
4. Identify tests to write
5. Surface any migrations or infra changes

**What you produce**: A plan presented in `EnterPlanMode`.

**Rule**: Never write code before the plan is approved via `ExitPlanMode`.

---

## Step 3: Implement

**When**: Plan is approved.

**Follow**:
- `docs/STANDARDS.md` — code quality rules
- `docs/BRANCHING.md` — correct branch name and PR target

**Branch naming**:
```
feature/<issue-number>-<short-description>   e.g. feature/42-user-registration
fix/<issue-number>-<short-description>       e.g. fix/55-expired-jwt
chore/<description>                          e.g. chore/upgrade-fastapi
```

---

## Step 4: Test (`/test`)

**When**: After any code change.

**Checks**:
1. `pytest tests/ --cov=src --cov-fail-under=80 -v`
2. `mypy src/`
3. `ruff check . && ruff format --check .`

**Rule**: Fix all failures before proceeding. Do not reduce coverage thresholds.

---

## Step 5: Commit (`/commit`)

**When**: Tests pass, code is ready.

**Process**:
1. Scan staged diff for secrets
2. Determine type and scope from the diff
3. Write Conventional Commit message (see CLAUDE.md)
4. Create commit with HEREDOC formatting

**Rule**: Never commit `.env` or files containing secrets.

---

## Step 6: Pull Request (`/pr`)

**When**: Branch is ready, CI is green.

**Process**:
1. Verify CI status with `gh run list`
2. Create PR with full description (summary, type of change, test plan, checklist)
3. Link related issues (`Closes #NNN`)

**Merge strategy**:
- `feature/*` → `develop`: **squash merge**
- `develop` → `main` (release): **merge commit**

---

## Step 7: Deploy (`/deploy`)

**When**: PR is merged into `main`.

**Process**:
1. Confirm you're on `main`
2. Check CI is green on `main`
3. Get explicit user confirmation
4. Trigger `deploy.yml` workflow (or it auto-triggers on push to `main`)
5. Monitor workflow with `gh run watch`
6. Verify `GET /health` returns 200

**Rollback**: See `.claude/commands/deploy.md` for rollback steps.

---

## Hotfix Flow

For urgent production fixes:

```
main ──── branch fix/<issue>-hotfix
              │
              ▼
          Implement + test
              │
              ▼
          PR → main (skip develop for speed)
              │
              ▼
          Merge commit → Deploy
              │
              ▼
          Cherry-pick or merge main → develop
```

---

## Architecture Decision Records (ADRs)

For significant technical decisions, create an ADR:

```
docs/adr/
  NNNN-<title>.md
```

Template:
```markdown
# ADR NNNN: <Title>

**Date**: YYYY-MM-DD
**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-NNNN

## Context
<What situation prompted this decision?>

## Decision
<What was decided?>

## Consequences
<What are the trade-offs? What becomes easier or harder?>
```
