#!/usr/bin/env bash
set -euo pipefail
repo="$GITHUB_REPOSITORY"
upstream="VD39/subsonic-player"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add upstream "https://github.com/$upstream.git"
git fetch origin main custom
git fetch upstream main

# Preserve main as a fast-forward-only mirror, never discard user commits.
if ! git merge-base --is-ancestor origin/main upstream/main; then
  echo "::error::main has diverged from upstream; resolve it manually."
  exit 1
fi
# Use GitHub's native fork-sync API to import upstream commits and workflows.
gh api --method POST "repos/$repo/merge-upstream" -f branch=main > /dev/null

release_file=$(mktemp)
trap 'rm -f "$release_file"' EXIT
gh api "repos/$upstream/releases/latest" > "$release_file"
release_id=$(jq -r '.id' "$release_file")
tag=$(jq -r '.tag_name' "$release_file")
release_url=$(jq -r '.html_url' "$release_file")
git check-ref-format "refs/tags/$tag"
git fetch upstream "refs/tags/$tag:refs/upstream-releases/$release_id"
release_sha=$(git rev-parse "refs/upstream-releases/$release_id^{commit}")

# Skip a release already incorporated into custom.
if git merge-base --is-ancestor "$release_sha" origin/custom; then
  echo "Latest official release $tag is already included."
  echo "No new official release; main mirror is current." >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

branch="updates/upstream-release-$release_id"
existing=$(gh pr list --repo "$repo" --base custom --head "$branch" --state all --json number,state --jq '.[0] // empty')
if [ -n "$existing" ] && [ "$(jq -r .state <<< "$existing")" != OPEN ]; then
  echo "This release PR was already closed or merged; no duplicate will be opened."
  exit 0
fi
if ! git ls-remote --exit-code origin "refs/heads/$branch" > /dev/null 2>&1; then
  # Start at the released upstream commit. GitHub merges its changes into custom
  # without removing custom-only changes; validation tests the PR merge ref.
  gh api --method POST "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$release_sha" > /dev/null
fi
if [ -n "$existing" ]; then
  pr=$(jq -r .number <<< "$existing")
else
  body=$(printf 'Proposes official upstream release **%s** into custom.\n\nRelease notes: %s\n\nThe combined version is validated with lint, types, unit tests, a production Docker build and a container smoke test. See the **Custom release validation** status. Merge only after reviewing the changes and successful checks. Merging into custom publishes the new GHCR image. No automatic merge or server deployment is performed. If GitHub reports conflicts, resolve them before merging.\n' "$tag" "$release_url")
  pr_url=$(gh pr create --repo "$repo" --base custom --head "$branch" --title "Update custom to upstream release $tag" --body "$body")
  pr="${pr_url##*/}"
fi
head_sha=$(git ls-remote origin "refs/heads/$branch" | cut -f1)
echo "pr=$pr" >> "$GITHUB_OUTPUT"
echo "sha=$head_sha" >> "$GITHUB_OUTPUT"
run_url="$GITHUB_SERVER_URL/$repo/actions/runs/$GITHUB_RUN_ID"
gh api --method POST "repos/$repo/statuses/$head_sha" -f state=pending -f context="Custom release validation" -f description="Testing the combined custom + upstream release" -f target_url="$run_url"
echo "Update PR: https://github.com/$repo/pull/$pr" >> "$GITHUB_STEP_SUMMARY"
