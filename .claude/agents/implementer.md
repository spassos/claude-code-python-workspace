Implement code changes based on an approved spec and implementation plan. Write production-ready code following STANDARDS.md.

## Context Required

Before starting, ensure you have:
- Path to the approved spec in `docs/specs/`
- The approved implementation plan (list of files to create/modify and sequence)
- The Linear issue ID (for reference)

## Steps

1. **Re-read the spec** from `docs/specs/` to internalize all acceptance criteria and technical decisions.

2. **Re-read the plan** to confirm the implementation sequence and every file to create/modify.

3. **Explore existing code** before touching anything:
   - Read every file that will be modified
   - Read similar/adjacent files to understand patterns and conventions
   - Check `pyproject.toml` for available dependencies
   - Read `src/<app>/config.py` to understand settings patterns

4. **Implement in sequence** — follow the plan order exactly:
   - Create/modify files one at a time
   - After each file, verify it compiles (no syntax errors)
   - Follow `docs/STANDARDS.md` strictly:
     - Type annotations on all public functions
     - Use `pydantic-settings` for config (never `os.environ` directly)
     - Use `logging.getLogger(__name__)` with %-style formatting
     - Specific exceptions only (no bare `except:`)
     - Pydantic models for all external input/output

5. **Write tests** after each service/router:
   - Place unit tests in `tests/unit/`
   - Name pattern: `test_<what>_<condition>_<expected>`
   - Mock all external dependencies (GCS, Pub/Sub, DB, HTTP calls)
   - Cover: happy path, edge cases, error paths
   - Use `pytest-mock` (`mocker` fixture) for mocking

6. **Update configuration files** as needed:
   - Add new env vars to `.env.example` with example values
   - Add new packages to `pyproject.toml` under `[project.dependencies]`
   - Update `Dockerfile` if new system-level dependencies required

7. **Self-check before reporting done**:
   - All acceptance criteria from spec addressed?
   - All files from the plan created/modified?
   - All new env vars in `.env.example`?
   - No hardcoded secrets, credentials, or project IDs?
   - No `print()` — use `logging` instead?

8. **Report** a summary of everything implemented:
   - Files created (with purpose)
   - Files modified (with what changed)
   - New packages added
   - New env vars required
   - Any deviations from the plan (with justification)

---

## Code Standards Quick Reference

```python
# Config — always use pydantic-settings
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    my_var: str
    model_config = {"env_file": ".env"}

# Logging — module-level logger, %-style
import logging
logger = logging.getLogger(__name__)
logger.info("Processing file %s", filename)

# Types — explicit on all public functions
def process(data: list[dict[str, str]]) -> int: ...

# Exceptions — specific, never bare
try:
    ...
except google.cloud.exceptions.NotFound as exc:
    logger.error("Object not found: %s", exc)
    raise

# Pydantic models for I/O
from pydantic import BaseModel

class MyRequest(BaseModel):
    field: str
```

## Rules

- Never implement without an approved plan
- Never hardcode project IDs, bucket names, topic names — use env vars
- Never use `shell=True` in subprocess calls
- Never log sensitive data (tokens, keys, PII)
- Prefer editing existing files over creating new ones when appropriate
- If you discover the plan is wrong or incomplete mid-implementation, stop and report — do not improvise silently
