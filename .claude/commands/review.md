Perform a thorough code review of the current branch versus the base branch.

## Steps

1. **Identify what to review**:
   ```bash
   git branch --show-current
   git log origin/develop..HEAD --oneline
   git diff origin/develop...HEAD --name-only
   ```

2. **Read every changed file** — use the Read tool to inspect the full file, not just the diff.

3. **Run automated checks first** (so you can reference results in review):
   ```bash
   ruff check .
   mypy src/
   pytest tests/ --cov=src --cov-report=term-missing -q
   ```

4. **Review each file** using the checklist below.

5. **Produce a structured review report** (see format below).

---

## Review Checklist

### Correctness
- [ ] Logic is correct for all specified acceptance criteria
- [ ] Edge cases handled (empty inputs, None, zero, max values)
- [ ] Error paths return appropriate HTTP status / raise correct exceptions
- [ ] No off-by-one errors in loops or slices

### Security
- [ ] No hardcoded secrets, tokens, or credentials
- [ ] All external input validated with Pydantic
- [ ] No `shell=True` in subprocess calls
- [ ] SQL queries use parameterized statements (no f-string SQL)
- [ ] Sensitive data is not logged
- [ ] File paths validated against traversal attacks if applicable

### Types & Code Quality
- [ ] `mypy --strict` passes with no suppressions
- [ ] No bare `except:` — specific exception types only
- [ ] No mutable default arguments in function signatures
- [ ] No global mutable state
- [ ] Functions are focused (single responsibility)

### Tests
- [ ] New code has unit tests
- [ ] Tests cover happy path, edge cases, and error paths
- [ ] Tests are not testing implementation details (avoid brittle tests)
- [ ] No `time.sleep()` in tests — use mocks for time-dependent logic
- [ ] Coverage ≥ 80% for new files

### Standards & Conventions
- [ ] Follows `docs/STANDARDS.md`
- [ ] Follows `docs/BRANCHING.md` conventions
- [ ] Commit messages follow Conventional Commits
- [ ] `.env.example` updated for new env vars
- [ ] No unnecessary comments or dead code

---

## Review Report Format

```
## Code Review: <branch-name>

**Commits reviewed**: N commits
**Files changed**: N files, +X/-Y lines

### Summary
<2-3 sentence overall assessment>

### Must Fix (blocking)
- `src/foo.py:42` — <issue description and suggested fix>

### Should Fix (non-blocking but important)
- `src/bar.py:15` — <issue description>

### Suggestions (optional improvements)
- `tests/test_foo.py` — <suggestion>

### Verdict
- [ ] Approved — ready to merge
- [ ] Approved with minor fixes — fix before merge
- [ ] Changes requested — address must-fix items and re-review
```

---

## Rules

- Be specific: cite file and line number for every comment
- Distinguish blocking issues from suggestions
- If you cannot determine correctness without domain context, ask the user
- Do not approve if there are security issues or failing tests
