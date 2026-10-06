# Changelog

## [0.5.1] — 2026-10-05

### Dependencies

- 🤖 Bump claude-code to 2.1.289
- 🐍 Bump uv to 0.12.23 and ruff to 0.16.10
- 🐹 Build on Go 1.27.1
- 📦 Bump pnpm to 11.28.4
- 🐳 Bump docker compose to 5.6.0 and the docker Python SDK to 7.2.0
- ☸️ Bump helm to 4.3.0 and the kubernetes.core collection to 6.6.0
- 🔎 Bump fzf to 0.74.4
- 📋 Bump go-task to 3.54.0
- ⚡ Bump ws-cli to Go 1.27.1 and its latest modules

## [0.5.0] — 2026-10-05

### Breaking

- 🚚 Move editor settings and extensions to `~/.local/share/ws-server/`; existing volumes are not migrated
- 🛒 Read the extension gallery from the `WS_MARKETPLACE_*` variables; `EXTENSIONS_GALLERY` is ignored
- 🗑️ Remove `/etc/workspace/config.yaml`; the editor is configured through `WS_*` variables only
- 🔐 Remove `WS_SERVER_SSL_ROOT`; self-signed certificates are minted in memory
- 🔤 Remove `ws serve font`; install fonts from their upstream projects

### Added

- 🆙 Ship VS Code 1.140.0
- 🎨 Rebrand the editor and docs with the Kloud Workspace icons
- 🚪 Add a Sign out action to the editor, overridable via `WS_EDITOR_LOGOUT_URL`
- 📁 Add `WS_EDITOR_DISABLE_FILE_DOWNLOADS` and `WS_EDITOR_DISABLE_FILE_UPLOADS`
- 🐞 Enable .NET debugging + revive terminal-link remap on the live workbench bundle *(#735)*
- 🌱 Seed files from a durable source directory on startup *(#727)*
- 📡 Add editor-state IPC routes + ws-cli editor; rewire open/openn
- ⌨️ Add ws completion via compdef ws=ws-cli
- 🤖 Agent-consumable documentation: `llms.txt`, `llms-full.txt`, per-page raw Markdown, and AI-crawler hints

### Changed

- 🌐 Treat a leading `*.` in `WS_SERVER_PROXY_DOMAIN` as the bare suffix instead of rejecting it
- 🔖 Single-source the workspace version through manifest.json
- 🫙 Swap to the `ws-cli` seed engine, retire the `vault` + seed tier *(#728)*
- 👷 Adopt shared ws-meta CI actions for changelog + PR emoji check
- 📜 Propagate CHANGELOG.md to ws-meta for the public surface *(#723)*

### Dependencies

- 🐍 Bump pylint to 4.1.2
- 🔑 Bump ansible-lint to 26.9.0 and op to 2.40.0
- 🧰 Bump deps: setup-node v6, claude-code, delve, uv, starship
- ⚡ Bump ws-cli to 0.0.69
- ⚡ Bump ws-cli to 0.0.68
- 📦 Bump claude-code, uv, pnpm, ruff
- 🐧 Bump base-image v0.1.2 (Debian 13.5) & ws-cli v0.0.65

### Fixed

- 🐳 Skip dockerd when CAP_NET_ADMIN is missing instead of restart-looping
- 🔗 Make `file://` terminal links clickable in browser *(#725)*

### Removed

- ✂️ Remove the `openn` alias

### Security

- 🛡️ Trust custom CAs in git, cargo & aws via CA-bundle env vars
- 🐋 Install `docker compose`/`buildx` from upstream releases *(#724)*

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
