Open a Pull Request for the current branch with a full description.

## Steps

1. **Check branch**: run `git branch --show-current` — confirm it is NOT `main` or `develop`.

2. **Check CI status**:
   ```bash
   gh run list --branch $(git branch --show-current) --limit 5
   ```
   If the latest CI run is not green (completed + success), stop and fix the issues first.

3. **Determine base branch**:
   - Feature/fix branches → base: `develop`
   - Hotfix branches → base: `main`
   - Release branches → base: `main`

4. **Read the diff** to understand all changes:
   ```bash
   git diff $(git merge-base HEAD origin/develop)...HEAD
   ```

5. **Find related issues**: check git log and branch name for issue numbers.

6. **Create the PR** using `gh pr create` with the template below.

7. **Confirm the PR URL** was created and share it with the user.

---

## PR Description Template

```markdown
## Summary

- <bullet: what this PR does>
- <bullet: why it was needed>
- <bullet: key implementation decision>

## Type of Change

- [ ] New feature (non-breaking change that adds functionality)
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update
- [ ] CI/CD / Infrastructure change

## Test Plan

- [ ] Unit tests added/updated — `pytest tests/unit/`
- [ ] Integration tests added/updated — `pytest tests/integration/`
- [ ] All tests pass — `pytest --cov=src --cov-fail-under=80`
- [ ] Type check passes — `mypy src/`
- [ ] Lint passes — `ruff check . && ruff format --check .`

## Checklist

- [ ] Code follows `docs/STANDARDS.md`
- [ ] No secrets or `.env` files committed
- [ ] `.env.example` updated if new env vars added
- [ ] `docs/SECRETS.md` updated if new GitHub secrets needed
- [ ] PR title follows Conventional Commits format

## Related Issues

Closes #NNN
```

---

## Merge Strategy

- PRs to `develop`: **squash merge** (clean linear history)
- PRs to `main` (releases): **merge commit** (preserve release boundary)

## Rules

- Never open a PR if CI is red
- Always link related issues (`Closes #NNN`)
- Request review from at least one team member (if applicable)
- Do not self-merge without review unless the repo allows it
