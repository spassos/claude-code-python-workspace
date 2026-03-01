Read the task, issue, or requirement provided by the user and produce a formal technical specification.

## Steps

1. **Understand the task** — ask clarifying questions if the requirement is ambiguous. Do not proceed with a spec until you understand:
   - What problem is being solved?
   - Who is the user/consumer?
   - What are the success criteria?

2. **Explore the codebase** — use Glob and Grep to understand:
   - Existing modules that may be affected
   - Current data models, API contracts, configurations
   - Related tests

3. **Produce the spec document** at `docs/specs/YYYY-MM-DD-<slug>.md` using the template below.

4. **Present the spec to the user** for review before any planning or implementation begins.

---

## Spec Document Template

```markdown
# Spec: <Feature Name>

**Date**: YYYY-MM-DD
**Author**: Claude Code
**Status**: Draft | Review | Approved
**Issue**: #NNN (if applicable)

---

## Problem Statement

<What problem does this solve? Why now?>

## Motivation

<Business or technical rationale. What happens if we don't do this?>

## Proposed Solution

<High-level description of the approach.>

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Decisions

| Decision | Options Considered | Chosen | Rationale |
|----------|--------------------|--------|-----------|
| ...      | ...                | ...    | ...       |

## Dependencies

- External services: ...
- Internal modules: ...
- New packages: ...

## Out of Scope

<Explicit list of what this spec does NOT cover.>

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ...  | Low/Med/High | Low/Med/High | ... |

## Complexity Estimate

- **Size**: XS / S / M / L / XL
- **Estimated effort**: <N> hours / days
- **Confidence**: High / Medium / Low

## Open Questions

1. ...
2. ...
```

---

## Rules

- Save the file before presenting it to the user
- Do not start `/plan` until the spec is approved
- If the task is trivial (< 30 min, single file), a brief spec in the chat is acceptable — still ask for confirmation before proceeding
