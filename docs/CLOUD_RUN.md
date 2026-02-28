# Cloud Run Setup Guide

Step-by-step guide to configure GCP and deploy to Cloud Run using GitHub Actions with Workload Identity Federation.

---

## Prerequisites

- GCP project created and billing enabled
- `gcloud` CLI installed and authenticated locally
- GitHub repository created

---

## Step 1: Enable GCP APIs

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=$GCP_PROJECT_ID
```

---

## Step 2: Create Artifact Registry Repository

```bash
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$GCP_REGION \
  --description="Docker images for $GCP_SERVICE_NAME" \
  --project=$GCP_PROJECT_ID
```

Image path will be:
```
$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME
```

---

## Step 3: Create Service Account for GitHub Actions

```bash
# Create the service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Deploy SA" \
  --project=$GCP_PROJECT_ID

# Grant required roles
SA_EMAIL="github-actions-sa@$GCP_PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountUser"
```

---

## Step 4: Configure Workload Identity Federation

This avoids long-lived service account keys.

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project=$GCP_PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get the pool name
WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "github-pool" \
  --project=$GCP_PROJECT_ID \
  --location="global" \
  --format="value(name)")

# Create the OIDC provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project=$GCP_PROJECT_ID \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow the GitHub repo to impersonate the service account
# Replace YOUR_GITHUB_ORG/YOUR_REPO with your actual values
GITHUB_REPO="YOUR_GITHUB_ORG/YOUR_REPO"

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project=$GCP_PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/$WORKLOAD_IDENTITY_POOL_ID/attribute.repository/$GITHUB_REPO"

# Get the provider resource name (needed for GitHub secret)
gcloud iam workload-identity-pools providers describe "github-provider" \
  --project=$GCP_PROJECT_ID \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"
```

---

## Step 5: Configure GitHub Secrets

Go to your GitHub repo → Settings → Secrets and variables → Actions.

Add these secrets (see `docs/SECRETS.md` for full list):

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_REGION` | e.g. `us-central1` |
| `GCP_SERVICE_NAME` | Name of the Cloud Run service |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Output from step 4 |
| `GCP_SERVICE_ACCOUNT` | `github-actions-sa@<project>.iam.gserviceaccount.com` |
| `GCP_ARTIFACT_REGISTRY` | `<region>-docker.pkg.dev/<project>/<repo>` |

---

## Step 6: Application Requirements

Your application **must**:

1. **Listen on port 8080** (or the `PORT` env var):
   ```python
   import os
   port = int(os.environ.get("PORT", 8080))
   ```

2. **Respond to `GET /health`** with HTTP 200:
   ```python
   @app.get("/health")
   async def health() -> dict[str, str]:
       return {"status": "ok"}
   ```

3. **Start within 10 seconds** (Cloud Run health check timeout)

4. **Be stateless** — no local file writes that need to persist across requests

---

## Step 7: Multi-Stage Dockerfile

See the `Dockerfile` in the repo root for the template. Key requirements:

- Use `--target production` for the final image
- Expose port 8080
- Run as non-root user
- Use slim or distroless base image

---

## Step 8: First Deploy

After pushing to `main`, the `deploy.yml` workflow triggers automatically.

To trigger manually:
```bash
gh workflow run deploy.yml --ref main
```

Monitor:
```bash
gh run watch
```

Verify:
```bash
SERVICE_URL=$(gcloud run services describe $GCP_SERVICE_NAME \
  --region $GCP_REGION \
  --format "value(status.url)")

curl -s $SERVICE_URL/health
# Expected: {"status": "ok"}
```

---

## Useful Commands

```bash
# List Cloud Run services
gcloud run services list --region $GCP_REGION

# View service details
gcloud run services describe $GCP_SERVICE_NAME --region $GCP_REGION

# View recent logs
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=$GCP_SERVICE_NAME" \
  --limit=50 \
  --format="table(timestamp, severity, textPayload)"

# List revisions
gcloud run revisions list --service $GCP_SERVICE_NAME --region $GCP_REGION

# Roll back to a previous revision
gcloud run services update-traffic $GCP_SERVICE_NAME \
  --region $GCP_REGION \
  --to-revisions REVISION_NAME=100
```

---

## Cost Optimization

- Set `--min-instances=0` for dev/staging (scales to zero)
- Set `--min-instances=1` for production (avoids cold starts)
- Set `--max-instances` to cap costs
- Set `--memory=512Mi` and `--cpu=1` as starting point; adjust based on metrics
- Use `--concurrency=80` (Cloud Run default) unless your app is CPU-bound
