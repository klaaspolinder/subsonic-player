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
After merge, **Publish custom image** runs validation again, then publishes
linux/amd64 and linux/arm64 images to:
`ghcr.io/klaaspolinder/subsonic-player:latest`
and `ghcr.io/klaaspolinder/subsonic-player:sha-<full commit SHA>`.
No image is published from update PRs, and this does not update a server.
The upstream Docker Hub workflows are not used by this setup.

## GitHub setup

Enable Actions for this fork. In Settings → Actions → General, enable
**Allow GitHub Actions to create and approve pull requests**.
Workflows request their own limited permissions; no personal access token
or Docker Hub credentials are required. Make the GHCR package public if
you want anonymous pulls (new packages may initially be private).

## Docker Compose

Keep your existing ports, restart policy and other settings; change image:

```yaml
image: ghcr.io/klaaspolinder/subsonic-player:latest
```

Then run `docker compose pull` and `docker compose up -d`.
For rollback use the previous `sha-...` tag.
