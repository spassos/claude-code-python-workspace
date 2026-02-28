# Code Standards

Python coding standards for this workspace.

---

## Language & Runtime

- **Python 3.12** (minimum). Test matrix includes 3.13.
- Use modern syntax: `match`/`case`, `X | Y` union types, `tomllib`, etc.
- Type annotations are **mandatory** on all public functions and methods.

---

## Project Layout

```
src/<app_name>/
  __init__.py           version string, nothing else
  main.py               app entrypoint (FastAPI app creation, lifespan)
  config.py             pydantic-settings Settings class
  routers/              one file per resource group
    __init__.py
    health.py           GET /health (always present)
    users.py
  services/             business logic, no HTTP concerns
    __init__.py
    user_service.py
  models/               Pydantic request/response models
    __init__.py
    user.py
  repositories/         data access layer (DB queries, external APIs)
    __init__.py
    user_repo.py
  exceptions.py         custom exception classes
  dependencies.py       FastAPI dependency functions

tests/
  conftest.py           shared fixtures (app client, DB session, etc.)
  unit/                 pure unit tests — no I/O, fast
  integration/          tests that hit DB/API — use test containers or mocks
```

---

## Formatter: ruff format

- Line length: **88** (Black-compatible)
- String quotes: **double quotes** (ruff default)
- Run: `ruff format .`
- Check: `ruff format --check .`

Configuration in `pyproject.toml`:
```toml
[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
```

---

## Linter: ruff check

Enabled rule sets:
- `E`, `W` — pycodestyle errors and warnings
- `F` — pyflakes
- `I` — isort (import ordering)
- `N` — pep8 naming
- `UP` — pyupgrade (modern syntax)
- `B` — flake8-bugbear
- `C4` — flake8-comprehensions
- `SIM` — flake8-simplify
- `TCH` — flake8-type-checking (move type-only imports to TYPE_CHECKING)

Run: `ruff check .`
Auto-fix safe issues: `ruff check --fix .`

---

## Type Checker: mypy

Run: `mypy src/`

Required configuration (`pyproject.toml`):
```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
```

### Rules

- `# type: ignore` is allowed only with an explanatory comment:
  ```python
  x = external_lib.foo()  # type: ignore[return-value] — lib missing stubs
  ```
- Use `typing.cast()` sparingly and only when you're certain of the type.
- Prefer `Protocol` over `ABC` for structural typing.
- Use `TypeVar` with bounds, not unconstrained `TypeVar("T")`.

---

## Imports

Order (enforced by ruff/isort):
1. Standard library
2. Third-party
3. First-party (your `src/` modules)
4. Local (relative imports within same package)

Separate each group with a blank line.

```python
from __future__ import annotations  # only if needed for forward refs

import asyncio
import logging
from typing import TYPE_CHECKING

import httpx
from fastapi import Depends, HTTPException

from app.config import Settings
from app.models.user import UserCreate

if TYPE_CHECKING:
    from app.repositories.user_repo import UserRepository
```

---

## Functions & Classes

```python
# Good: explicit types, docstring only when non-obvious
def get_user(user_id: int, db: Session) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# Good: dataclass for simple value objects
from dataclasses import dataclass

@dataclass(frozen=True)
class UserId:
    value: int


# Bad: mutable default argument
def append_item(item: str, items: list[str] = []) -> list[str]:  # WRONG
    items.append(item)
    return items

# Good:
def append_item(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items
```

---

## Error Handling

```python
# Bad: bare except
try:
    result = risky_operation()
except:
    pass

# Good: specific exception, meaningful handling
try:
    result = risky_operation()
except ValueError as exc:
    logger.warning("Invalid input: %s", exc)
    raise HTTPException(status_code=422, detail=str(exc)) from exc
except httpx.TimeoutException:
    raise HTTPException(status_code=504, detail="Upstream timeout")
```

Custom exceptions:
```python
class AppError(Exception):
    """Base exception for this application."""

class NotFoundError(AppError):
    """Resource not found."""

class ValidationError(AppError):
    """Business rule validation failed."""
```

---

## Configuration

Use `pydantic-settings`:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    anthropic_api_key: str
    gcp_project_id: str
    gcp_region: str = "us-central1"
    log_level: str = "INFO"
    port: int = 8080

settings = Settings()
```

- **Never** hardcode environment values
- **Never** access `os.environ` directly — always go through `Settings`
- `.env.example` must list every variable with a blank value and a comment

---

## Logging

```python
import logging

logger = logging.getLogger(__name__)

# Good
logger.info("Processing user %s", user_id)
logger.error("Failed to connect to DB: %s", exc, exc_info=True)

# Bad: f-string in log (evaluated even if level disabled, may leak secrets)
logger.info(f"Processing user {user_id}")  # WRONG
logger.debug(f"Token: {token}")            # NEVER
```

Configure in `main.py`:
```python
logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
```

---

## Testing

```python
# Fixture pattern
import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client() -> TestClient:
    return TestClient(app)

# Test naming: test_<what>_<condition>_<expected>
def test_get_user_when_exists_returns_200(client: TestClient) -> None:
    response = client.get("/users/1")
    assert response.status_code == 200
    assert response.json()["id"] == 1

def test_get_user_when_not_found_returns_404(client: TestClient) -> None:
    response = client.get("/users/99999")
    assert response.status_code == 404
```

- Use `pytest.mark.parametrize` for multiple input scenarios
- Use `unittest.mock.patch` or `pytest-mock` for external dependencies
- No `time.sleep()` in tests — mock `time` or use event loop control
- No `assert` in fixtures — use `pytest.raises` for expected exceptions

---

## Security

- Validate all external input with Pydantic models
- Never use `shell=True` in `subprocess` calls
- Parameterize all SQL queries (no f-string SQL)
- Never log tokens, passwords, or PII
- Use `secrets.token_urlsafe()` for generating tokens, not `random`
- Run `bandit -r src/` — zero HIGH severity findings allowed
