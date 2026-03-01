# Setup GitHub Actions Secrets

Configure all required GitHub Actions secrets for Cloud Run deployment.

## When to use

Run this command when setting up a new project or when secrets are missing/stale.

## Steps

1. **Read the GitHub token** from `~/.claude/settings.json`:
   ```python
   import json
   settings = json.load(open(os.path.expanduser("~/.claude/settings.json")))
   token = settings["mcpServers"]["github"]["env"]["GITHUB_PERSONAL_ACCESS_TOKEN"]
   ```

2. **Get the repository's public key** (required to encrypt secrets):
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     "https://api.github.com/repos/$OWNER/$REPO/actions/secrets/public-key"
   ```
   Save `key_id` and `key` from the response.

3. **Collect secret values** from the user. Required secrets:

   | Secret | Description | Example |
   |--------|-------------|---------|
   | `GCP_PROJECT_ID` | GCP project ID | `my-project-123456` |
   | `GCP_ARTIFACT_REGISTRY` | Full Artifact Registry URL | `us-central1-docker.pkg.dev/my-project/my-app` |
   | `GCP_WORKLOAD_IDENTITY_PROVIDER` | WIF provider resource name | `projects/123/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
   | `GCP_SERVICE_ACCOUNT` | Deploy service account email | `github-actions-sa@my-project.iam.gserviceaccount.com` |

4. **Encrypt and create each secret** using PyNaCl (install if needed: `pip3 install PyNaCl`):
   ```python
   import base64, json, urllib.request
   from nacl import public

   TOKEN = "..."
   REPO = "owner/repo"
   KEY_ID = "..."
   KEY = "..."  # base64

   pub_key = public.PublicKey(base64.b64decode(KEY))
   box = public.SealedBox(pub_key)

   secrets = {
       "GCP_PROJECT_ID": "...",
       # ... outros secrets
   }

   for name, value in secrets.items():
       encrypted = base64.b64encode(box.encrypt(value.encode())).decode()
       payload = json.dumps({"encrypted_value": encrypted, "key_id": KEY_ID}).encode()
       req = urllib.request.Request(
           f"https://api.github.com/repos/{REPO}/actions/secrets/{name}",
           data=payload, method="PUT",
           headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
       )
       with urllib.request.urlopen(req) as resp:
           print(f"{name}: OK (HTTP {resp.status})")
   ```

5. **Verify** all secrets are listed:
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     "https://api.github.com/repos/$OWNER/$REPO/actions/secrets" \
     | python3 -c "import sys,json; [print(s['name']) for s in json.load(sys.stdin)['secrets']]"
   ```

## Rules

- **Never print or log** the actual secret values
- **Never commit** secrets to any file
- Always verify the token has `repo` scope (classic PAT) or `Secrets: read/write` (fine-grained PAT)
- If HTTP 403: the token lacks permission — ask user to update token in `~/.claude/settings.json`
