# Shared Files

Central hub for files shared across KloudKIT repos.

## Flow

```txt
Origin repos ── push --> `shared/<repo>/` ── distribute --> Downstream repos
```

1. **Origin repos:** *(workspace, ws-cli, etc.)* push files to `shared/<repo>/` using the
   reusable [sync action](../.github/actions/sync/action.yaml).
2. **`distribution.yaml`:** maps those files to destinations in downstream repository.
3. **Distribute workflow:** detects changes and creates PRs *(or direct pushes)* to each
   downstream repository.

Origins know nothing about consumers. Adding a new shared resource means adding an entry to `distribution.yaml`.

## Usage in Origin Repository

```yaml
---
- uses: kloudkit/ws-meta/.github/actions/sync@main
  with:
    token: ${{ secrets.KLOUD_BOT_ORG_PAT }}
    files: |
      path/to/file.yaml
      path/to/directory/
```

Files land in `shared/<repo-name>/` automatically.

## `distribution.yaml`

Maps `shared/` paths to downstream repo destinations:

```yaml
---
shared/workspace/env.reference.yaml:
  - repo: ws-docs
    path: .vitepress/data/env.reference.yaml

  - repo: ws-helm
    path: charts/workspace/scripts/env.reference.yaml
```

Set `pr: false` on a target to direct-push to main instead of opening a PR *(default: `true`)*.
