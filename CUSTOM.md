# Custom Subsonic Player

This fork keeps the narrow-desktop track-list change on `custom`.
`main` is a fast-forward-only mirror of VD39/subsonic-player main.
The original PR branch is separate and remains unchanged.

## Updates

`custom` is the default branch so scheduled workflows run there.
Every day at 06:17 UTC, **Propose upstream releases** refreshes main and
checks the latest official, non-prerelease GitHub release upstream.
It opens one update PR into custom per new release, and never merges it.
The combined PR merge result gets lint, type, unit-test, production Docker
build and container HTTP smoke checks. The result appears as
**Custom release validation**, including when GitHub does not automatically
run checks for a bot-created PR. Conflicts fail validation and need review.
Closed update PRs are not repeatedly recreated. Previously closed or merged PRs are recognized by release ID. You can run the sync again through Actions.

Review the update PR and its green validation result before merging.
Pushes to custom run **Custom validation** without publishing an image.
After reviewing and merging the PR, explicitly start **Actions → Publish custom
image → Run workflow**, selecting branch **custom**. This manual action approves
publication of the selected custom commit. The workflow runs validation again,
then builds and smoke-tests both native architectures before publishing
linux/amd64 and linux/arm64 images to:
`ghcr.io/klaaspolinder/subsonic-player:latest`
and `ghcr.io/klaaspolinder/subsonic-player:sha-<full commit SHA>`.
No image is published from update PRs, and this does not update a server.
The upstream Docker Hub preview and latest jobs are restricted to
`VD39/subsonic-player`; they skip in this fork. The main mirror and release-update
PRs never trigger the custom GHCR publisher. Publishing is workflow_dispatch only;
there is no push, workflow_run or upstream-release publication trigger.
Each run validates and builds its fixed github.sha, even if custom moves later.

## GitHub setup

Enable Actions for this fork. In Settings → Actions → General, enable
**Allow GitHub Actions to create and approve pull requests**.
Workflows request their own limited permissions. No Docker Hub credentials are required.

Upstream releases can change files in `.github/workflows`. GitHub's built-in
`GITHUB_TOKEN` cannot import these changes, even through the fork-sync API.
Create a fine-grained personal access token with resource owner `klaaspolinder`,
repository access limited to `klaaspolinder/subsonic-player`, and these repository
permissions: **Contents: Read and write**, **Workflows: Read and write**.
Store it as the repository Actions secret **UPSTREAM_SYNC_TOKEN** under
Settings → Secrets and variables → Actions. Choose an expiration and renew the
secret before it expires. Do not commit or paste the token into issues or chat.
The token is used only to sync main and create upstream release branch refs;
PR creation and validation statuses still use the built-in GITHUB_TOKEN.
After adding the secret, run **Propose upstream releases → Run workflow** on
`custom`. Re-running an old failed run uses its old workflow code. Make the GHCR package public if
you want anonymous pulls (new packages may initially be private).

## Repository protections and upstream workflows

In Settings → Rules → Rulesets, protect `custom`: require a pull request, require
successful **Custom validation** checks, and block force pushes/deletions. Select
the actual validation check name from a completed run. Do not allow automatic
upstream merges. The sync workflow's **Custom release validation** status is an
additional result for bot-created release PRs; verify it is green before merging.
If you require a reviewer approval, use another collaborator: GitHub does not
allow authors to approve their own PRs. For a solo maintainer, manual review and
merge plus the explicit publish dispatch are the approval steps.

Disable **Docker Publish Preview** and **Docker Publish Latest** in Actions using
each workflow's menu → Disable workflow. This repository-level setting also
covers the unchanged upstream workflows on the mirrored `main` branch and
protects against future upstream imports overwriting the guards on `custom`.
Do not add Docker Hub secrets to fix an unused publisher. Leave **CI**, **Custom
validation**, **Propose upstream releases** and **Publish custom image** enabled.
The connected integration cannot change these repository settings.

The manual dispatch is the required publication decision; no environment is
needed. If an independent approval is desired, configure a protected GitHub
environment and reference it on every job that writes packages (both `publish`
and `manifest`); creating an environment alone does not enforce approval.

## Docker Compose

Keep your existing ports, restart policy and other settings; change image:

```yaml
image: ghcr.io/klaaspolinder/subsonic-player:latest
```

Then run `docker compose pull` and `docker compose up -d`.
For rollback use the previous `sha-...` tag.
