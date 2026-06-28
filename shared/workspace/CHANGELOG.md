# Changelog

## [Unreleased]

### Added

- ✨ Agent-consumable documentation: `llms.txt`, `llms-full.txt`, per-page raw Markdown, and AI-crawler hints

### Security

- 🔒 Trust custom CAs in `git`, `cargo`, and `aws` via per-tool CA-bundle env vars

## [0.4.0] — 2026-06-23

### Breaking

- 💥 Reject wildcard proxy domains instead of silently stripping the `*.` prefix
- 💥 Move shell/REPL history to `~/.ws/history`; history at the previous paths is not migrated *(#704)*

### Added

- ✨ dotnet: Debian 13 trixie + selectable version bands (8.0/9.0/10.0)
- ✨ Install additional pip packages and uv tools via env vars *(#703)*
- ✨ Install additional npm packages via `WS_NPM_ADDITIONAL_PACKAGES`
- ✨ Run `cloudflared` as a supervised s6 tunnel daemon *(#700)*
- ✨ Skip feature-install sections via `--skip-*` flags *(#698)*
- ✨ Enable built-in Markdown features and markdownlint parity *(#697)*
- ✨ Add user feature playbooks under `~/.ws/features.d` *(#696)*
- ✨ Query `show env` by canonical dotted keys, retire WS_* query form *(#693)*
- ✨ Enforce WS_* value validation via declared patterns
- ✨ Retire common.sh env wrappers into `ws-cli show env`
- ✨ Add in-workspace OIDC auth via oauth2-proxy *(#690)*
- ✨ Add fonts.yaml manifest and render to fonts.sh *(#683)*

### Changed

- 🏗️ Automate release tagging and changelog from a WS_VERSION literal *(#722)*
- ♻️ dotnet: DRY the version var, trim zshenv comments
- 🚚 Move shell/REPL history to `~/.ws/history` and consolidate env into `zshenv` *(#704)*
- ♻️ Extract `github_binary` role task and sweep feature playbooks *(#701)*
- 🚚 Replace `dumb-init` with `s6-overlay` v3 daemon supervision *(#699)*
- 🏗️ Audit image build: isolate code-server into a cache-stable stage *(#695)*
- 🏗️ Audit dependency manifest: sudo PATH parity + Renovate hygiene *(#694)*
- 🚀 Swap jedi for pyrefly LSP *(#689)*

### Fixed

- 🐛 Fixed renovate syntax
- 🐛 Own proxy-domain {{port}} prefix in startup, reject wildcards

## [0.3.0] — 2026-06-01

### Added

- ✨ Add a `--target` flag to `ws-cli logs` for the metrics and `dockerd` components
- ✨ Add the `ripgrep` fast recursive search tool
- ✨ Add the `tshark` terminal network-protocol analyzer
- ✨ Add GitHub authentication support
- ✨ Bundle the `syft`, `grype`, `dive`, and `osv-scanner` SBOM and vulnerability tools as an `image-extras` feature
- ✨ Add a `version` option to the `cpp` feature and support offline installation
- ✨ Add a `WS_APT_DISABLE_RESTRICTIONS` toggle

### Changed

- 🏗️ Slim the dev image and install `pnpm` from npm
- 🏗️ Render `extensions.sh` from a new `extensions.yaml` manifest
- 🏗️ Harden the `~/.ws/` convention: add `ca.d/` and drop the override environment variables
- 🏗️ Resolve the pip and npm registries from the environment or user config
- 🏗️ Add a drift-safe APT resolver for `ws-feature-store` drift
- 🏗️ Route additional APT installs through a feature playbook
- 🚚 Move `dive` to an opt-in feature
- ♻️ Migrate secret-shaped and path-shaped `WS_*` variables to the `secret: true` and `type: path` schema flags
- ♻️ Read every `WS_*` variable through `ws-cli show env`, dropping `check_env_set` and `resolve_secret`
- 🏗️ Add `server.ssl_root` and an absolute `secrets.vault` default

### Removed

- 🔥 Trim dead-weight bundled assets from the VSCode extensions

### Fixed

- 🐛 Fix a prompt-hide regression and harden the zsh shell-init layer
- 🐛 Harden the workspace startup scripts for first boot
- 🐛 Fix the Claude statusline ahead/behind icons to match starship
- 🐛 Fix web-font loading and cache the static assets
- 🐛 Rename `server.root_dir` to `server.root` to match the runtime environment variable
- 🐛 Stamp debug "Skipped" lines from the `common.sh` environment helpers

### Security

- 🔒 Deny CNI plugins by default

### Dependencies

- ⬆️ Bump the `base-image` to `v0.1.1`
- ⬆️ Bump `ws-cli`
- ⬆️ Bump `ansible-core` to `v2.21.0`

## [0.2.1] — 2026-05-05

### Dependencies

- ⬆️ Bump `kubectl`

## [0.2.0] — 2026-04-27

### Added

- ✨ Add the GitLab CLI
- ✨ Add the `claude-code` CLI
- ✨ Add the `bun` JavaScript runtime as a feature
- ✨ Add a `notify` endpoint to the IPC interface
- ✨ Add an opt-in open-code (`oc`) environment
- ✨ Support a custom `.ws` configuration directory

### Changed

- 🚚 Move `oc` into a feature
- 🚚 Migrate to `uv` for Python package management
- 🚚 Move delimited parsing to the `dilimit` helper
- 🏗️ Source features from `ws-feature-store`
- 🏗️ Package build artifacts as well

### Fixed

- 🐛 Fix `fzf` history search

### Dependencies

- ⬆️ Update Helm to v4
