Run the test suite and report results. Fix failures before proceeding.

## Steps

1. **Run full test suite with coverage**:
   ```bash
   pytest tests/ \
     --cov=src \
     --cov-report=term-missing \
     --cov-fail-under=80 \
     -v
   ```

2. **Analyze results**:
   - If all tests pass and coverage ≥ 80%: report success, proceed to `/commit`
   - If tests fail: go to step 3
   - If coverage < 80%: go to step 4

3. **Fix test failures**:
   - Read the full failure output and traceback
   - Identify root cause (don't just silence the test or mock more aggressively)
   - Fix the implementation or the test (prefer fixing the implementation)
   - Re-run only the failing tests first: `pytest tests/ -k "<test_name>" -v`
   - Then re-run the full suite to confirm no regressions

4. **Fix coverage gaps**:
   - Read `--cov-report=term-missing` to see which lines are uncovered
   - Add tests for untested branches, edge cases, error paths
   - Do not add trivial tests just to hit the number — test meaningful behavior

5. **Run type check** (always do this alongside tests):
   ```bash
   mypy src/
   ```
   Fix any type errors before committing.

6. **Run linter**:
   ```bash
   ruff check . && ruff format --check .
   ```
   Auto-fix safe issues: `ruff check --fix . && ruff format .`

7. **Report final status** to the user:
   - Test count: X passed, Y failed, Z skipped
   - Coverage: XX%
   - Type check: OK / N errors
   - Lint: OK / N issues

---

## Quick Commands

```bash
# Run only unit tests
pytest tests/unit/ -v

# Run only integration tests
pytest tests/integration/ -v

# Run a specific test file
pytest tests/unit/test_foo.py -v

# Run tests matching a name pattern
pytest -k "test_auth" -v

# Run with extra output on failure
pytest --tb=long -v

# Check types only
mypy src/ --show-error-codes

# Auto-fix lint
ruff check --fix . && ruff format .
```

---

## Rules

- Never proceed to `/commit` with failing tests
- Never reduce coverage thresholds to make CI pass — add tests instead
- Never add `# noqa` or `# type: ignore` without an explanatory comment
- If a test is genuinely flaky (not your code), mark it with `@pytest.mark.flaky` and open an issue
