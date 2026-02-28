# Branching Strategy

Git workflow for this workspace.

---

## Branch Model

```
main
 │    Production. Always deployable. Protected.
 │    Direct commits: forbidden.
 │    Merge from: develop (release), fix/*-hotfix (hotfixes)
 │    Merge strategy: merge commit (preserves release boundary)
 │
develop
 │    Integration branch. All features land here first. Protected.
 │    Direct commits: forbidden.
 │    Merge from: feature/*, fix/*, chore/*, refactor/*
 │    Merge strategy: squash merge (clean linear history)
 │
 ├── feature/<issue-number>-<slug>
 │       New functionality. Branches from develop.
 │       e.g. feature/42-user-registration
 │
 ├── fix/<issue-number>-<slug>
 │       Bug fixes. Branches from develop (or main for hotfixes).
 │       e.g. fix/55-expired-jwt
 │
 ├── chore/<slug>
 │       Tooling, deps, docs, CI changes. Branches from develop.
 │       e.g. chore/upgrade-fastapi-0.115
 │
 ├── refactor/<slug>
 │       Code restructuring without behavior change. Branches from develop.
 │       e.g. refactor/extract-user-service
 │
 └── release/<version>
         Optional. Used when preparing a versioned release.
         Branches from develop. Merged into main AND back into develop.
         e.g. release/1.2.0
```

---

## Branch Naming Rules

- Use **kebab-case** (hyphens, no underscores or spaces)
- Include the **issue number** when one exists: `feature/42-description`
- Keep slugs **short and descriptive** (2-4 words max)
- Prefix determines CI trigger and PR target:

| Prefix | PR Target | Merge Strategy |
|--------|-----------|----------------|
| `feature/*` | `develop` | Squash |
| `fix/*` | `develop` | Squash |
| `chore/*` | `develop` | Squash |
| `refactor/*` | `develop` | Squash |
| `release/*` | `main` | Merge commit |
| `fix/*-hotfix` | `main` | Merge commit |

---

## Creating a Branch

```bash
# Always branch from the latest develop
git fetch origin
git checkout -b feature/42-user-registration origin/develop

# Or for hotfixes, branch from main
git checkout -b fix/99-critical-data-loss origin/main
```

---

## Keeping Your Branch Up to Date

```bash
# Rebase onto develop to incorporate latest changes
git fetch origin
git rebase origin/develop

# If conflicts arise, resolve them file by file:
# git add <resolved-file>
# git rebase --continue
```

Prefer **rebase** over merge for feature branches to keep history clean.

---

## Commit Message Convention

Format: `<type>(<scope>): <description>`

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting (no logic change) |
| `refactor` | Code restructuring (no behavior change) |
| `test` | Adding or updating tests |
| `chore` | Tooling, deps, CI, build scripts |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |
| `build` | Build system changes |
| `revert` | Reverting a previous commit |

**Examples**:
```
feat(api): add POST /users endpoint
fix(auth): handle expired tokens without 500 error
chore(deps): bump httpx from 0.27 to 0.28
ci: add Python 3.13 to test matrix
docs(cloud-run): add workload identity setup steps
```

**Body** (when needed):
```
feat(api): add rate limiting to /users endpoint

Without rate limiting, a single client could exhaust DB connections.
Implemented using slowapi (token bucket, 100 req/min per IP).

Closes #78
```

---

## Protected Branches

Configure in GitHub → Settings → Branches:

### `main`
- Require PR before merge
- Require status checks: `lint`, `typecheck`, `test-py312`, `test-py313`
- Require conversation resolution
- No force push
- No deletion

### `develop`
- Require PR before merge
- Require status checks: `lint`, `typecheck`, `test-py312`
- No force push

---

## Release Process

1. When `develop` is stable and ready for release:
   ```bash
   git checkout -b release/X.Y.Z origin/develop
   ```
2. Update version in `pyproject.toml`, update `CHANGELOG.md`
3. Open PR from `release/X.Y.Z` → `main`
4. After merge: tag the release
   ```bash
   git tag -a vX.Y.Z -m "Release X.Y.Z"
   git push origin vX.Y.Z
   ```
5. Merge `main` back into `develop`:
   ```bash
   git checkout develop
   git merge main --no-ff -m "chore: sync main into develop after release X.Y.Z"
   ```

---

## Hotfix Process

For urgent production bugs that cannot wait for the next release:

```bash
git checkout -b fix/99-critical-issue-hotfix origin/main
# fix, test, commit
# PR → main (squash)
# after merge: cherry-pick or merge main → develop
git checkout develop
git merge main --no-ff -m "chore: sync hotfix for #99 into develop"
```
