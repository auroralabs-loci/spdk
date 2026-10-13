# LOCI Mirror Template

Template for mirroring upstream repositories with LOCI analysis.

## Setup

1. Create repo from this template
2. Add topic `loci-mirror` to receive automatic overlay updates
3. Configure the required variables and secrets below
4. Create the `LOCI_PROJECT` project in the LOCI dashboard
5. Add the repo to the `loci-review` GitHub App (Org Settings > GitHub Apps > loci-review > Repository access), which posts the PR comments and checks

## Required Configuration

### Variables (`Settings > Variables > Actions`)

| Variable | Description |
|----------|-------------|
| `UPSTREAM_REPO` | Upstream repo to mirror (e.g., `openssl/openssl`) |
| `MIRROR_MAX_UPSTREAM_PRS` | Max new mirror PRs per UTC day, pending ones included (e.g., `2`) |
| `MIRROR_UPSTREAM_PR_LOOKBACK_DAYS` | Only mirror PRs updated within N days (e.g., `2`) |
| `SYNC_PRS_HOURS` | Hours (UTC) to run PR sync (e.g., `1,5,9,13,17,21`). A run GitHub starts late is still accepted in the following hour; one successful sync per window. Empty = every hour |
| `LOCI_PROJECT` | LOCI project name (e.g., the repo name); the project must exist in the LOCI dashboard |
| `LOCI_BACKEND_URL` | LOCI backend API URL |
| `LOCI_ENV` | LOCI environment (optional, defaults to `PROD__AL_DEMO`) |

### Secrets (`Settings > Secrets and variables > Actions`)

| Secret | Description |
|--------|-------------|
| `MIRROR_REPOS_WRITE_PAT` | PAT with repo write access (push branches, create PRs) |
| `LOCI_API_KEY` | LOCI API key |

### Topics

To get fresh updates from mirror-template repository, make sure to add `loci-mirror` topic to your repo. 

## Restricting Upstream Actions

To prevent upstream workflows from running in your mirror, restrict allowed actions:

1. Go to **Settings → Actions → General**
2. Under "Actions permissions", select **Allow auroralabs-loci, and select non-auroralabs-loci, actions and reusable workflows**
3. In the text box, add the following (replace `REPO_NAME` with your upstream repo name):

```
!auroralabs-loci/REPO_NAME/.github/workflows/*,
actions/cache@v3,
actions/checkout@v5,
actions/setup-python@v5.6.0,
auroralabs-loci/REPO_NAME/.github/workflows/loci-analysis.yml@*,
auroralabs-loci/REPO_NAME/.github/workflows/sync-upstream-prs.yml@*,
auroralabs-loci/REPO_NAME/.github/workflows/process-pending-prs.yml@*,
auroralabs-loci/REPO_NAME/.github/workflows/notify-insightful-prs.yml@*,
```

This blocks all upstream workflows (`!.../*`) and then whitelists only the LOCI workflows and required actions.

> **Note:** This configuration only restricts which actions and reusable workflows can be *called from within* a workflow. It does **not** prevent workflows from being triggered by events (push, pull_request, schedule, etc.). Upstream workflows that were synced into `.github/workflows/` and do not call restricted workflows can still run.
>
> To fully prevent a synced upstream workflow from running, disable it manually per repository:
> - **UI:** Go to **Actions** tab → select the workflow in the sidebar → click **...** → **Disable workflow**
> - **CLI:** `gh workflow disable <workflow-filename-or-name>`

## Customization

Edit `.github/workflows/loci-analysis.yml` and search for `@configure:` comments:

| Location | What to change |
|----------|----------------|
| `LOCI_PROJECT` | Your LOCI project name, if not the `LOCI_PROJECT` variable |
| `Install dependencies` step | Commands to install build tools |
| `Build` step | Commands to build your binaries |
| `binaries:` | Paths to built binaries for upload |

## How It Works

- **`sync-upstream-prs.yml`**: Syncs `main` to upstream, creates `loci/main-${sha}` branches with overlay, and mirrors upstream PRs as `loci/pr-${num}-${branch}` (or `loci/pending-pr-*` when the base branch is new)
- **`process-pending-prs.yml`**: Promotes `loci/pending-pr-*` branches to `loci/pr-*` and creates mirror PRs
- **`loci-analysis.yml`**: Runs LOCI analysis on pushes to `loci/main-*` and on PRs
- **`sync-overlay.yml`**: *(template repo only)* Syncs overlay changes to all repos with `loci-mirror` topic