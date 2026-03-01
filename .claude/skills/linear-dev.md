Automate the full development workflow for a Linear issue: spec → plan → implement → test → commit → PR → Linear update.

## Usage

```
/linear-dev <ISSUE-ID>
```

Example: `/linear-dev SPA-26`

---

## How Agents Work

Custom agents live in `.claude/agents/`. They are invoked via the `Agent` tool with
`subagent_type: "general-purpose"` — with a prompt that instructs the agent to **read
the corresponding `.claude/agents/<name>.md` file first**, then follow its instructions.

This pattern applies to: `plan`, `implementer`, `pr`, `spec`, `deploy`.

---

## Steps

### 1. Fetch the Linear Issue

Use the `mcp__linear__get_issue` tool with the provided issue ID. Extract:
- Title
- Description
- Current status
- Labels and priority

If the issue is not found, stop and report the error.

### 2. Check for Existing Spec

Search for an approved spec file:
```bash
ls docs/specs/ 2>/dev/null | grep -i "<issue-slug>"
```

Also search by issue ID pattern in spec files:
```bash
grep -rl "<ISSUE-ID>" docs/specs/ 2>/dev/null
```

**If no approved spec exists:**
> "Issue <ID> has no approved spec in `docs/specs/`. Run `/spec <ISSUE-ID>` first, get it approved, then re-run `/linear-dev <ISSUE-ID>`."
Stop here.

**If a spec exists but Status is not `Approved`:**
> "Spec found at `<path>` but status is `<status>`. Get it approved first."
Stop here.

### 3. Create a Feature Branch

```bash
git checkout main && git pull origin main
git checkout -b <branch-name>
```

Use the branch name from the Linear issue (`gitBranchName` field) if available.
Otherwise derive it: `feat/spa-<N>-<short-slug>`.

### 4. Spawn Plan Agent

Use the `Agent` tool with `subagent_type: "general-purpose"`. In the prompt, include:

```
Working directory: <absolute-path>
Read and follow the instructions in `.claude/agents/plan.md`.

Context:
- Spec file: <spec-path>
- Linear issue: <ISSUE-ID> — <title>
- Issue description: <description>
```

Wait for the agent to present the plan via EnterPlanMode. **Do not proceed until the user approves the plan.**

### 5. Spawn Implementer Agent

Use the `Agent` tool with `subagent_type: "general-purpose"`. In the prompt, include:

```
Working directory: <absolute-path>
Read and follow the instructions in `.claude/agents/implementer.md`.

Context:
- Spec file: <spec-path>
- Approved plan: <full plan details from step 4>
- Linear issue: <ISSUE-ID>
```

Wait for the agent to finish and report a summary of all files created/modified.

### 6. Run Tests

Execute the full quality gate:
```bash
cd <working-directory>
python -m pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=80 -v
mypy src/
ruff check . && ruff format --check .
```

**If any check fails**, spawn the implementer agent again (same pattern as step 5) to fix
the failures. Pass the full error output in the prompt. Re-run the quality gate after.
Do not proceed to commit until all checks pass.

### 7. Stage and Commit

Stage only the feature files (not `.claude/`, `scripts/`, `CLAUDE.md`):
```bash
git add src/ tests/ docs/specs/ pyproject.toml .env.example infra/ .github/
```

Then commit in conventional format:
```bash
git commit -m "$(cat <<'EOF'
feat(<scope>): <description from issue title>

<body: what was implemented and why>

Closes <ISSUE-ID>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 8. Push and Open PR

```bash
git push -u origin <branch-name>
```

Use the `Agent` tool with `subagent_type: "general-purpose"`. In the prompt, include:

```
Working directory: <absolute-path>
Read and follow the instructions in `.claude/agents/pr.md`.

Context:
- Branch: <branch-name>
- Linear issue: <ISSUE-ID> — <title>
- Implemented files: <list from implementer summary>
```

### 9. Update Linear Issue

After the PR is open:
- Use `mcp__linear__save_issue` to add the PR URL as a link and move to `In Review`
- Use `mcp__linear__create_comment`:

```
PR aberto: <PR_URL>

Workflow executado automaticamente via `/linear-dev`.
```

### 10. Report Summary

```
## /linear-dev Summary

**Issue**: <ID> — <Title>
**Branch**: <branch-name>
**PR**: <PR_URL>

### Implemented
- <bullet per major deliverable>

### Quality Gate
- Tests: X passed, coverage: XX%
- mypy: OK
- ruff: OK

### Next Step
Merge the PR when CI is green, then run `/deploy`.
```

---

## Rules

- **Never skip a step** — each gate (spec, plan approval, tests) exists for a reason
- **Never commit with failing tests** — fix first, always
- **Never open a PR without CI being green**
- **Never move the Linear issue to Done** — that happens after deploy, not after PR
- If the user interrupts at any step, preserve work done so far (staged files, branch)
- If the spec is missing, do not attempt to infer requirements from the issue description alone — spec is mandatory
