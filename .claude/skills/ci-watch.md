# Watch CI Workflows

Monitor GitHub Actions workflow runs for a given commit and report results.

## When to use

After a `git push` to any branch — confirm CI is green before opening a PR or deploying.

## Steps

1. **Get the current commit SHA**:
   ```bash
   git rev-parse --short HEAD
   ```

2. **Read token** from `~/.claude/settings.json`:
   ```python
   import json, os
   s = json.load(open(os.path.expanduser("~/.claude/settings.json")))
   token = s["mcpServers"]["github"]["env"]["GITHUB_PERSONAL_ACCESS_TOKEN"]
   ```

3. **Poll workflow runs** until all finish (status ≠ `queued`/`in_progress`/`waiting`):
   ```python
   import urllib.request, json, time

   TOKEN = "..."
   REPO = "owner/repo"
   SHA = "abc1234"

   while True:
       req = urllib.request.Request(
           f"https://api.github.com/repos/{REPO}/actions/runs?per_page=20",
           headers={"Authorization": f"Bearer {TOKEN}"}
       )
       with urllib.request.urlopen(req) as r:
           runs = json.load(r)["workflow_runs"]

       # Filter to current commit
       runs = [r for r in runs if r["head_sha"].startswith(SHA)]

       for r in runs:
           status = r["conclusion"] or r["status"]
           print(f"{r['name']:<30} {status}")

       pending = [r for r in runs if (r["conclusion"] or r["status"]) in ("queued", "in_progress", "waiting")]
       if not pending:
           break
       time.sleep(15)
   ```

4. **On failure**: fetch failing job steps for context:
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/jobs" \
     | python3 -c "
   import sys, json
   for j in json.load(sys.stdin)['jobs']:
       for s in j['steps']:
           if s['conclusion'] == 'failure':
               print(f'FAIL [{j[\"name\"]}]: {s[\"name\"]}')
   "
   ```

5. **Report** final status clearly to the user:
   - ✅ All green → safe to continue
   - ❌ Failure found → show failing step, fix before proceeding

## Rules

- Never open a PR or trigger deploy if CI is not green
- Poll interval: 15 seconds (respect GitHub API rate limits)
- If `gh` CLI is authenticated, prefer `gh run watch` for richer output
