Create a Conventional Commit for the currently staged changes.

## Steps

1. **Check staged files**: run `git diff --staged --name-only` to see what will be committed.

2. **Safety check** — abort immediately if any of these are staged:
   - `.env` or `*.env` files
   - Files containing patterns like `sk-`, `AIza`, `AKIA`, private keys, passwords
   - Run `git diff --staged` and scan for secrets before proceeding

3. **Read the diff**: run `git diff --staged` to understand the full set of changes.

4. **Determine type and scope**:
   - **Type**: `feat` | `fix` | `docs` | `style` | `refactor` | `test` | `chore` | `perf` | `ci` | `build` | `revert`
   - **Scope**: the module/area affected (e.g., `api`, `auth`, `db`, `config`, `deploy`, `deps`, `tests`, `docs`)
   - If changes span many areas, use the most impactful one or omit scope

5. **Write the commit message**:
   - Subject line: `<type>(<scope>): <imperative description>` — max 72 chars
   - Blank line
   - Body: explain *why* the change was made (not *what* — that's in the diff)
   - Footer: `Closes #NNN` if applicable, `BREAKING CHANGE:` if applicable

6. **Create the commit** using a HEREDOC to preserve formatting:
   ```bash
   git commit -m "$(cat <<'EOF'
   feat(api): add POST /users endpoint with email validation

   Users need to self-register without admin intervention.
   Added input validation via Pydantic and duplicate-email check.

   Closes #42
   EOF
   )"
   ```

7. **Verify**: run `git log --oneline -3` to confirm the commit was created.

---

## Commit Message Rules

- Subject line: imperative mood ("add", not "added" or "adds")
- No period at the end of the subject
- Body lines: max 100 chars
- Reference issues in footer, not subject
- `BREAKING CHANGE:` in footer triggers a major version bump

## What NOT to commit

- `.env`, `.env.local`, `.env.production`, or any file with real secrets
- `__pycache__/`, `.mypy_cache/`, `.ruff_cache/`, `*.pyc`
- Test coverage reports (`.coverage`, `htmlcov/`)
- IDE files (`.idea/`, `.vscode/` — unless `.vscode/settings.json` is team-shared)

If forbidden files are staged, unstage them first: `git restore --staged <file>`
