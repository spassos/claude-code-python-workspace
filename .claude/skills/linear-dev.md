Automate the full development workflow for a Linear issue: spec → plan → implement → test → commit → PR → Linear update.

## Usage

```
/linear-dev <ISSUE-ID>
```

Example: `/linear-dev SPA-26`

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

Use the `Agent` tool with `subagent_type: "plan"` to design the implementation plan.
Pass the spec file path and issue context. Wait for the plan agent to present the plan.

**Do not proceed until the plan is approved by the user.**

### 5. Spawn Implementer Agent

Use the `Agent` tool with `subagent_type: "implementer"` to write the code.
Pass:
- Spec file path
- Approved plan details
- Linear issue ID

Wait for the implementer to finish and report a summary.

### 6. Run Tests

Execute the full quality gate:
```bash
pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=80 -v
mypy src/
ruff check . && ruff format --check .
```

**If any check fails:**
- Fix the failures inline (do not skip)
- Re-run until all checks pass
- Do not proceed to commit with red tests

### 7. Stage and Commit

```bash
git add -p   # review what is staged
```

Then run the commit workflow (conventional commit format):
```bash
git commit -m "$(cat <<'EOF'
feat(<scope>): <description from issue title>

<body: what was implemented and why>

Closes <ISSUE-ID>
EOF
)"
```

### 8. Push and Open PR

```bash
git push -u origin <branch-name>
```

Use the `Agent` tool with `subagent_type: "pr"` to open the PR with full description linking to the Linear issue.
Pass:
- Current branch name
- Linear issue ID and title
- List of implemented files (from implementer summary)

### 9. Update Linear Issue

After the PR is open:
- Use `mcp__linear__save_issue` to update the issue:
  - Add PR URL as a link attachment
  - Move status to `In Review` (if that state exists)
  - Add a comment with the PR URL:

```
mcp__linear__create_comment:
  issueId: <issue-id>
  body: "PR aberto: <PR_URL>\n\nWorkflow executado automaticamente via `/linear-dev`."
```

### 10. Report Summary

Print a final summary:
```
## /linear-dev Summary

**Issue**: <ID> — <Title>
**Branch**: <branch-name>
**PR**: <PR_URL>
**CI**: <link to GitHub Actions run>

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
