Trigger a deploy to Cloud Run and monitor the result.

## Steps

1. **Verify branch**: confirm you are on `main`.
   ```bash
   git branch --show-current
   ```
   If not on `main`, stop. Deploy is only triggered from `main`.

2. **Verify the latest CI is green**:
   ```bash
   gh run list --branch main --limit 3
   ```
   If the last run on `main` failed, stop and investigate before deploying.

3. **Confirm with the user** — this is a production deployment. Ask:
   > "About to trigger deploy to Cloud Run for service `<GCP_SERVICE_NAME>` in project `<GCP_PROJECT_ID>`.
   > Confirm? (yes/no)"

   Do not proceed without explicit confirmation.

4. **Trigger the deploy workflow** manually (if needed):
   ```bash
   gh workflow run deploy.yml --ref main
   ```
   Or confirm that the push to `main` already triggered it automatically.

5. **Monitor the workflow**:
   ```bash
   gh run watch
   ```
   Follow the logs and surface any errors to the user.

6. **Get the service URL** after successful deploy:
   ```bash
   gcloud run services describe $GCP_SERVICE_NAME \
     --region $GCP_REGION \
     --format "value(status.url)"
   ```

7. **Verify the health endpoint**:
   ```bash
   curl -s https://<service-url>/health
   ```
   Expected: `{"status": "ok"}` with HTTP 200.

8. **Report** the service URL and deploy status to the user.

---

## Rollback

If the deploy fails or the health check returns non-200:

```bash
# List recent revisions
gcloud run revisions list --service $GCP_SERVICE_NAME --region $GCP_REGION

# Roll back to previous revision
gcloud run services update-traffic $GCP_SERVICE_NAME \
  --region $GCP_REGION \
  --to-revisions <PREVIOUS_REVISION>=100
```

---

## Rules

- **Never deploy without explicit user confirmation**
- **Never deploy from a branch other than `main`**
- Always check CI status before triggering
- If deploy fails, investigate logs before retrying
- Document failed deploys in the relevant PR/issue
