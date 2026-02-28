# Secrets Configuration

List of all secrets required to run CI/CD and deploy to Cloud Run.

**Rule**: Never commit actual secret values. This file only documents what secrets exist and where to configure them.

---

## GitHub Actions Secrets

Configure at: `GitHub repo → Settings → Secrets and variables → Actions → Secrets`

### Required for Deploy (`deploy.yml`)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `GCP_PROJECT_ID` | GCP project ID | `my-project-123456` |
| `GCP_REGION` | GCP region for Cloud Run | `us-central1` |
| `GCP_SERVICE_NAME` | Cloud Run service name | `my-app` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full resource name of the WIF provider | `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT` | Email of the deploy service account | `github-actions-sa@my-project.iam.gserviceaccount.com` |
| `GCP_ARTIFACT_REGISTRY` | Artifact Registry base URL | `us-central1-docker.pkg.dev/my-project/my-repo` |

### Required for Security Scanning (`security.yml`)

No additional secrets needed — uses Workload Identity from deploy.

### Optional (add as your app needs them)

| Secret Name | Description |
|-------------|-------------|
| `ANTHROPIC_API_KEY` | For apps using Claude API |
| `DATABASE_URL` | PostgreSQL connection string (use Cloud SQL with IAM auth instead when possible) |
| `SLACK_WEBHOOK_URL` | For deployment/alert notifications |

---

## GitHub Actions Variables (non-secret)

Configure at: `GitHub repo → Settings → Secrets and variables → Actions → Variables`

These are for non-sensitive configuration that can be visible in logs.

| Variable Name | Description | Example |
|---------------|-------------|---------|
| `GCP_REGION` | Can also be a variable if not sensitive | `us-central1` |
| `PYTHON_VERSION` | Default Python version for CI | `3.12` |

---

## Cloud Run Environment Variables

Set via `gcloud run deploy --set-env-vars` or in `deploy.yml`.

**Never use GitHub secrets directly as Cloud Run env vars** for sensitive values.
Instead, use **GCP Secret Manager** and reference secrets from Cloud Run:

```bash
# Store secret in GCP Secret Manager
echo -n "my-secret-value" | gcloud secrets create MY_SECRET \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# Grant Cloud Run service account access
gcloud secrets add-iam-policy-binding MY_SECRET \
  --member="serviceAccount:$CLOUD_RUN_SA@$GCP_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=$GCP_PROJECT_ID

# Reference in Cloud Run (automatically loaded as env var)
gcloud run deploy $SERVICE_NAME \
  --set-secrets="MY_SECRET=MY_SECRET:latest"
```

---

## Local Development Secrets

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in values in `.env` — **never commit this file**.

3. `.env` is in `.gitignore` — verify with:
   ```bash
   git check-ignore -v .env
   ```

4. Use `detect-secrets` to prevent accidental commits:
   ```bash
   pip install detect-secrets
   detect-secrets scan > .secrets.baseline
   detect-secrets audit .secrets.baseline
   ```

---

## Secret Rotation

When rotating a secret:

1. Generate new secret value
2. Update in GitHub Actions secrets (or GCP Secret Manager)
3. Redeploy the Cloud Run service to pick up the new value:
   ```bash
   gcloud run services update $GCP_SERVICE_NAME \
     --region $GCP_REGION \
     --update-secrets="MY_SECRET=MY_SECRET:latest"
   ```
4. Verify the service still returns healthy
5. Revoke / delete the old secret value

---

## Security Checklist

- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` is committed (with blank values)
- [ ] `detect-secrets` baseline is committed
- [ ] No secrets in `pyproject.toml`, `CLAUDE.md`, or any docs
- [ ] Cloud Run uses Secret Manager, not plain env vars, for sensitive values
- [ ] Service accounts follow least privilege principle
- [ ] Workload Identity Federation configured (no long-lived keys)
