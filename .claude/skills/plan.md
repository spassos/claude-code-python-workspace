Read the approved spec and design a concrete implementation plan. Get user approval before writing any code.

## Steps

1. **Read the spec** — locate the spec file in `docs/specs/` or read what the user provided.

2. **Explore the codebase thoroughly**:
   - Use Glob to map the file structure
   - Use Grep to find related functions, classes, imports
   - Read key files to understand existing patterns and conventions
   - Check `pyproject.toml` for available dependencies

3. **Design the implementation**:
   - List every file to be **created** (with purpose)
   - List every file to be **modified** (with what changes)
   - Define the implementation sequence (order matters for dependencies)
   - List tests to write (unit and integration)
   - Flag any migrations, config changes, or infra updates needed

4. **Use `EnterPlanMode`** to present the plan and wait for approval.

5. **Only after approval**: begin implementation following `docs/STANDARDS.md`.

---

## Plan Output Format

Present this structure in plan mode:

```
## Implementation Plan: <Feature Name>

### Files to Create
- `src/<app>/routers/foo.py` — new API router for X
- `tests/unit/test_foo.py` — unit tests for foo module

### Files to Modify
- `src/<app>/main.py` — register new router
- `src/<app>/models/bar.py` — add new field Y

### Implementation Sequence
1. Add Pydantic model in `models/`
2. Implement service logic in `services/`
3. Create router in `routers/`
4. Register router in `main.py`
5. Write unit tests
6. Write integration tests

### Tests Required
- Unit: test model validation, service logic (mocked dependencies)
- Integration: test endpoint end-to-end (test client)

### Other Changes
- [ ] Database migration needed? No / Yes (describe)
- [ ] New environment variables? No / Yes (list in .env.example)
- [ ] New GitHub secrets? No / Yes (describe in docs/SECRETS.md)
- [ ] Dockerfile changes? No / Yes (describe)

### Risks
- <Any implementation risk or uncertainty>
```

---

## Rules

- Never begin implementing without explicit user approval via ExitPlanMode
- If the codebase is empty/new, state that clearly and propose the initial structure
- If you discover the spec is incomplete during exploration, surface the gap and ask before planning
- Prefer modifying existing files over creating new ones when appropriate
