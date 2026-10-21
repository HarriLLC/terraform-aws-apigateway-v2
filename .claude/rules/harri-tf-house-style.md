# Harri Terraform — House Style

Shared conventions for Harri Terraform `.tf` files (workspaces, modules,
generic). Repo-specific naming, module versions, environments, and the
imports.tf-removal rule stay in each repo's own `CLAUDE.md`.

> Scope note: these are `.tf` / resource-block rules. Terraform Stacks files
> (`*.tfcomponent.hcl` / `*.tfdeploy.hcl`) use component/deployment blocks and
> have their own conventions in the Stacks template — several bullets here
> (resource argument order, `data.tf`, variable/output field order) do not
> apply to them.

- **Data sources**: live in a separate `data.tf`, positioned before the
  resources that reference them.
- **`moved {}` — change an address without destroying.** Renaming a resource,
  a module call, or a `for_each` key (a map key in a workspaces env included)
  changes its address, and without a `moved` block Terraform destroys the old
  object and creates a new one. Whenever an address changes in code that
  already has state, add `moved { from = … to = … }`. The blocks live in a
  separate `moved.tf` beside the `main.tf` whose resources they re-address,
  never inline in resource files. In a module, keep them: consumers upgrade
  later and still need the move. In a root, delete them once the apply has
  landed in every workspace.
- **`removed {}` — stop managing without destroying.** Deleting a resource block
  destroys the real object on the next apply. When the object must survive —
  handed to another repo or system, or managed by hand from now on — replace the
  block with `removed { from = … lifecycle { destroy = false } }`: Terraform
  drops it from state and leaves it in place. `from` names a whole resource or
  module, never a single `for_each` instance, so dropping one map entry this
  way is not possible — ask before reaching for a state operation instead. The
  blocks live in a separate `removed.tf` beside `moved.tf`, need Terraform
  `>= 1.7`, and are deleted once the apply has landed in every workspace.
  Removing a resource also means removing its `import` block.
- **Variables**: `type` + `description` required; snake_case. Use
  `optional(type, default)` for nested object fields.
- **Variable block field order**: `type`, `description`, `default`,
  `sensitive`, `validation`.
- **Output block field order**: `type`, `description`, `value`, `sensitive`.
- **Resource argument order**: `count`/`for_each` first, then a blank line,
  then non-block arguments, then block arguments, then `lifecycle`, then
  `depends_on`.
- **Blank lines within blocks**: separate logical groups of arguments with
  empty lines.
- **`count` vs `for_each`**: use `count` for near-identical instances; use
  `for_each` when arguments differ per instance.
- **Policy documents are external files**: IAM and resource policies (queue,
  bucket, ECR, inline role policies) live as `.json` or `.json.tftpl` files in
  a sibling directory (e.g. `queue_policies/`, `bucket_policies/`) and are
  loaded with `file()` or `templatefile()`. Never inline a policy as a heredoc.
- **Module versions are pinned exactly** — everywhere, consumers included. The
  `version` beside a `module` block's `source` is a real semver (`version =
  "X.Y.Z"`), never a range. A module can change behaviour between any two
  releases, so a floating pin means a plan you did not write.
- **Provider versions are ranges** — `~> 5.0` or `>= 5.0`, not a single version.
  This holds in consumers as well as inside modules: every provider constraint in
  the fleet is a range. Providers are additive within a major, so a range picks up
  fixes without a PR, and `.terraform.lock.hcl` is what actually pins the version
  a run uses. **A ranged provider pin is correct, not drift.** What *is* worth
  flagging is a range that has fallen behind a major — `~> 4.0` when the standard
  is `~> 5.0`.
- **Version constraints depend on whether the code is shared or a root.**
  This covers both `required_version` and provider versions.
  - **Shared code states a minimum version only** — a `terraform-aws-*`
    module's `versions.tf`, and a workspaces repo's `common/versions.tf`. Use
    `>= X.Y.Z` with no upper bound, kept deliberately wide so every consumer can
    run something newer. Don't "tighten" it to a single patch.
  - **A root module states what it actually runs** — an env's `terraform.tf` in
    a workspaces repo. A narrower `~>` constraint (`~> 1.16`, `aws ~> 6.0`) is
    correct there, and it must fall within the shared code's minimum.
  - Remove any legacy hard cap such as `<= 1.5.7`, wherever it is; it blocks
    Terraform upgrades and is never intentional here.
- **Tags — the standard keys, applied once**: every taggable resource carries
  `Environment`, `Ownership`, and `terraform-project`, applied at the provider
  level in a `default_tags` block so they land on every resource automatically.
  In a workspaces repo that provider lives in the environment root module, and
  the values are written literally there; a shared `local.common_tags` is the
  older form. The `Ownership` default is per repo (e.g. `backend`,
  `frontend`). Never re-declare those keys on individual resources or map
  entries; only add per-resource `tags` for values genuinely specific to that
  resource.
- **No hardcoded secrets**: never put credentials, tokens, or keys in Terraform
  files. Source them from env vars, HCP Terraform variable sets, or Vault (for
  modules,
  the consumer supplies them). Mark secret-holding variables `sensitive = true`.
- **Indentation**: two spaces per nesting level. `terraform fmt` is run for you
  by the toolkit's hook each time a `.tf` file is written; CI enforces it too.
- **Validate locally before opening a PR.** In the directory you changed, run
  `terraform init -upgrade=false` (plain `init` only when there is no
  `.terraform.lock.hcl`) then `terraform validate`. A local `terraform plan` is
  fine for verification wherever a backend is configured. **Never run
  `terraform apply` locally** — applies go through HCP Terraform or the
  project's pipeline. The type-specific rule for this project adds the detail.
- **Comments**: use `#` for both single- and multi-line comments; only comment
  to clarify non-obvious intent.
- **`.gitignore`**: exclude `*.tfstate`, `*.tfstate.backup`, `.terraform/`,
  `*.tfplan`, and any `.tfvars` holding secrets. Keep `.terraform.lock.hcl`
  committed.
