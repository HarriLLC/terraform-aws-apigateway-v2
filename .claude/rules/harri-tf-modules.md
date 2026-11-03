# Harri Terraform — Module Conventions

Applies to reusable modules, published to the HCP private registry as
`app.terraform.io/harri/<name>/aws`, and to local child modules under `modules/`.

- **File set**: `variables.tf`, `data.tf`, `locals.tf`, `resources.tf`,
  `outputs.tf`, `versions.tf`, `README.md`, plus policy templates as root-level
  `.json` / `.json.tftpl` rendered with `templatefile()`. **`resources.tf` is
  the standard** — `main.tf` in a module is legacy and is reported as drift.
- **Always expose `outputs.tf`.** A module with no outputs gives consumers
  nothing to wire; its absence is a gotcha, not a style choice.
- **Version floors, not pins.** `versions.tf` declares `required_version` as a
  floor of at least `>= 1.9.0` and provider constraints as lower-bound ranges
  (e.g. `aws >= 5.0`) so each consumer can pin exact. Never tighten a module's
  floor to a single patch, and never add an upper cap.
- **Registry address**: `app.terraform.io/harri/<name>/aws`, where `<name>` is
  the module name **as registered in the HCP private registry**, set by hand at
  publish time. Harri convention is the repo name minus `terraform-aws-`
  (`terraform-aws-sqs-module` → `sqs-module`), but verify it against a
  consumer's `source =` line; never assume. Legacy `Terraform*Module` names have
  no convention to derive from.
- **Publishing**: version by semver. A new **required** input, or a renamed or
  removed output, is a breaking change and a **major** bump; a new optional
  input is minor; a fix is patch. Update `README.md` before tagging, and
  `CHANGELOG.md` if the module keeps one. Then tag and push **that one tag**,
  with an **annotated** tag carrying a message that says what changed:

  ```bash
  git tag -a vX.Y.Z -m "short note on what this version changes"
  git push origin vX.Y.Z
  ```

  HCP auto-publishes from the tag. Consumers pin the exact, `v`-stripped value
  (`X.Y.Z`, not `vX.Y.Z`).
- **Test before merge with an `-rc` tag.** To try a change in a consumer before
  the PR merges, tag a release candidate **from the feature branch**, numbered
  for the version the merge will become:

  ```bash
  git tag -a vX.Y.Z-rc.1 -m "rc: short note on what is being tested"
  git push origin vX.Y.Z-rc.1
  ```

  Pin it exactly (`X.Y.Z-rc.1`); a range such as `~> X.Y` never selects a
  pre-release. Use it in a non-prod consumer only, bump `-rc.2`, `-rc.3`… for
  each new round, and never leave an `-rc` pinned once the PR merges: tag the
  final `vX.Y.Z` from the default branch and move every consumer to it.
- **A module holds no state.** Local checks are `terraform fmt`, `terraform
  init -upgrade=false`, `terraform validate`. Never `plan` or `apply` a module
  directly; that happens in the consumer.
