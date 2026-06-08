# CLAUDE.md

> Vendored copy of the upstream `terraform-aws-modules/apigateway-v2` (serverless.tf),
> republished to the Harri private registry. This is the module the
> microservice module consumes (`app.terraform.io/harri/apigateway-v2/aws`).

## What This Module Provisions

API Gateway v2 (HTTP / WebSocket), gated by `create` + per-area `create_*` flags:

- `aws_apigatewayv2_api.this` — the HTTP or WebSocket API (`protocol_type`).
- `aws_apigatewayv2_authorizer.this` — one per `authorizers` entry (REQUEST / JWT).
- `aws_apigatewayv2_route.this` / `aws_apigatewayv2_route_response.this` — per `routes` entry.
- `aws_apigatewayv2_integration.this` / `aws_apigatewayv2_integration_response.this` — per `integrations` entry.
- `aws_apigatewayv2_stage.this` (+ `aws_apigatewayv2_deployment.this`, `aws_cloudwatch_log_group.this["this"]` for access logs).
- `aws_apigatewayv2_vpc_link.this` — one per `vpc_links` entry.
- **Custom domain** (when `create_domain_name`): `aws_apigatewayv2_domain_name.this`, `aws_apigatewayv2_api_mapping.this` + `.this_additional`, optional Route53 records (`create_domain_records`) and `module.acm` certificate (`create_certificate`).

## Registry Source

```hcl
module "api_gateway" {
  source  = "app.terraform.io/harri/apigateway-v2/aws"
  version = "1.0.1"

  name          = "dev-http"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "authorization"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }
}
```

> Upstream source is `terraform-aws-modules/apigateway-v2/aws`. Consumers in Harri pin the private-registry version.

## Required Versions

| Component | Constraint |
|---|---|
| Terraform | `>= 1.3` |
| AWS provider (`hashicorp/aws`) | `>= 5.37` |

Source of truth: `versions.tf`. (Harri Terraform-core standard is `>= 1.9.0`; AWS `>= 5.37` already exceeds the `>= 5.0` standard.)

## File Layout

```
terraform-aws-apigateway-v2/
├── variables.tf    # All inputs (api / authorizers / domain / routes / integrations / stage / vpc links)
├── main.tf         # All resources + acm module + route53 data/record (no resources.tf)
├── outputs.tf      # api / domain / stage / integrations / routes / vpc links
├── migrations.tf   # moved {} blocks for the v4 → v5 upgrade
├── versions.tf     # required_version + AWS provider
├── README.md       # Upstream usage docs
├── examples/       # complete-http, vpc-link-http, websocket
└── wrappers/       # for_each wrapper around the root module
```

## Inputs (selected)

Full list in `variables.tf` / README. The module is map-driven with `create_*` toggles:

| Name | Type | Default | Description |
|---|---|---|---|
| `create` | `bool` | `true` | Master switch for all resources. |
| `name` | `string` | `""` | API name. |
| `protocol_type` | `string` | `"HTTP"` | `HTTP` or `WEBSOCKET`. |
| `cors_configuration` | `object` | `null` | CORS config (HTTP APIs). |
| `authorizers` | `map(object)` | `{}` | Authorizers (REQUEST / JWT). |
| `routes` | `map(object)` | `{}` | Routes (+ optional route response), referencing `authorizer_key` / `integration_key`. |
| `integrations` | `map(object)` | `{}` | Integrations (AWS_PROXY / HTTP_PROXY), referencing `vpc_link_key`, with optional `tls_config` / response. |
| `create_stage` | `bool` | `true` | Create the default stage. |
| `stage_name` | `string` | `"$default"` | Stage name. |
| `stage_access_log_settings` | `object` | `{}` | Access-log + log-group config. |
| `stage_default_route_settings` | `object` | `{}` | Throttling / metrics defaults. |
| `additional_stage_api_mappings` | `map(object)` | `{}` | Extra `domain_name` → `api_mapping_key` mappings. |
| `create_domain_name` / `create_domain_records` / `create_certificate` | `bool` | `true` | Custom-domain toggles. |
| `domain_name` / `subdomains` / `hosted_zone_name` | — | — | Custom-domain inputs. |
| `vpc_links` | `map(object)` | `{}` | VPC links (name / SGs / subnets). |

## Outputs

Key outputs: `api_id`, `api_endpoint`, `api_arn`, `api_execution_arn`; `authorizers`, `integrations`, `routes`, `vpc_links` (full maps); `domain_name_*`, `acm_certificate_arn`; `stage_id`, `stage_arn`, `stage_invoke_url`, `stage_execution_arn`, `stage_domain_name`; `stage_access_logs_cloudwatch_log_group_name`/`_arn`. See `outputs.tf`.

## Examples

- `examples/complete-http` — HTTP API with authorizers, routes/integrations, custom domain, access logs.
- `examples/vpc-link-http` — HTTP API fronting a private integration via a VPC link.
- `examples/websocket` — WebSocket API.

## Validate Changes Locally

- Run `terraform fmt` before opening a PR (always — CI may fail otherwise).
- From the module dir: `terraform init -upgrade=false` (pulls the `acm` module).
- Run `terraform validate`.
- **Do not run `terraform plan` or `terraform apply` locally** — modules don't hold state on their own; that happens in the consumer stack.

## Publishing a New Version

1. Make the changes and run `terraform validate`.
2. Update `README.md` / `migrations.tf` (`moved` blocks) if resources are renamed.
3. Tag the commit: `git tag vX.Y.Z && git push --tags`.
4. HCP Registry auto-publishes from the tag at `app.terraform.io/harri/apigateway-v2/aws`; bump consumers' `version` pins (e.g. `terraform-aws-microservice-module`).

## Conventions & Naming

### Project naming patterns

- All resources use the logical name `this`; multiplicity comes from `for_each` over the config maps (`authorizers`, `routes`, `integrations`, `vpc_links`, `additional_stage_api_mappings`) or `count` on the singletons (api, stage, domain).
- Routes/integrations cross-reference each other and authorizers/VPC links by **map key** (`integration_key`, `authorizer_key`, `vpc_link_key`) rather than ARNs.
- Optional areas are toggled by `create_*` flags; `create = false` disables everything.
- `migrations.tf` carries `moved {}` blocks for the v4 → v5 rename (`aws_apigatewayv2_stage.default` → `.this`; log group → keyed `["this"]`) — keep these for in-place upgrades.
- Custom domain depends on `module.acm` (`terraform-aws-modules/acm`) when `create_certificate = true`.

### Universal house style

- Variables: `type` + `description` required; snake_case; `nullable` declared explicitly. Use `optional(type, default)` for nested object fields.
- Module / component versions pinned to exact semver (e.g. `version = "4.1.1"`), not ranges.
- **Comments**: use `#` for both single-line and multi-line comments. Only comment to clarify non-obvious intent.
- **No hardcoded secrets**: never put credentials, tokens, or keys in Terraform files. Source them from env vars, TFC variable sets, or Vault (for modules, the consumer supplies them). Mark secret-holding variables with `sensitive = true`.
- **Indentation**: two spaces per nesting level (`terraform fmt` enforces — required before every PR).
- **Variable block field order**: `type`, `description`, `default`, `sensitive`, `validation`.
- **Output block field order**: `type`, `description`, `value`, `sensitive`.
- **Resource argument order**: `count`/`for_each` first, then a blank line, then non-block arguments, then block arguments, then `lifecycle`, then `depends_on`.
- **Blank lines within blocks**: separate logical groups of arguments with empty lines.
- **`count` vs `for_each`**: use `count` for nearly identical instances; use `for_each` when arguments differ per instance.
- **Tags — don't duplicate `default_tags`**: shared/common tags are applied once at the provider level via `default_tags { tags = local.common_tags }`, so they already land on every resource. **Never re-declare those same tags on individual resources or map entries** — only add `tags` to a resource for values that are genuinely resource-specific and not already in `common_tags`. Duplicating the common tags per-resource is redundant and drifts.
- **Data sources**: live in a separate `data.tf` file, logically positioned before the resources that reference them.
- **`.gitignore`**: exclude `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `*.tfplan`, and any `.tfvars` holding secrets. Keep `.terraform.lock.hcl` committed.

### Module-specific

- File set: `variables.tf`, `main.tf`, `outputs.tf`, `versions.tf`, `migrations.tf`, `README.md`, `examples/`, `wrappers/`.
- Required versions standard: `terraform >= 1.9.0`, `aws >= 5.0`.
- Registry source convention: `app.terraform.io/harri/{name}/aws`.
- Publish: `git tag vX.Y.Z` → HCP Registry auto-publish.
- Tests: `terraform test` with `mock_provider "aws" {}`.
