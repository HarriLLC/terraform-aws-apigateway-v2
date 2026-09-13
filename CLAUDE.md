# terraform-aws-apigateway-v2

Harri's fork of `terraform-aws-modules/apigateway-v2`, republished to the HCP
private registry. Upstream structure and inputs are kept; Harri consumers drive
it from `TerraformAPIGateway/common/apis` and from the microservice module.

## What This Module Provisions

- `aws_apigatewayv2_api` (HTTP or WebSocket) with an optional `$default` stage
  (`aws_apigatewayv2_stage`, plus `aws_apigatewayv2_deployment` for WebSocket)
  and a CloudWatch access-log group.
- Routes and integrations from the `routes` / `integrations` maps
  (`aws_apigatewayv2_route`, `_integration`, and their `_response` variants),
  plus `aws_apigatewayv2_authorizer` per `authorizers` entry.
- A custom domain (`aws_apigatewayv2_domain_name`), its API mappings
  (`aws_apigatewayv2_api_mapping`, including `additional_stage_api_mappings`),
  and Route 53 A/AAAA records for the domain and `subdomains`.
- Optional `aws_apigatewayv2_vpc_link` per `vpc_links` entry, and an ACM
  certificate when `create_certificate`.
- Every group is behind a `create_*` toggle so a caller can reuse an existing
  domain or stage.

## Registry Source

```hcl
module "api_gateway" {
  source  = "app.terraform.io/harri/apigateway-v2/aws"
  version = "1.0.1"

  # no required inputs — set at least these in practice
  name          = "prep-my-service"
  protocol_type = "HTTP"
  routes        = { "ANY /{proxy+}" = { integration = { uri = "..." } } }
}
```

## Required Versions

| Component | Constraint |
|---|---|
| Terraform | `>= 1.3` |
| AWS provider | `>= 5.37` |

Source of truth: `versions.tf`. The provider constraint is intentionally a
range so each consumer can pin an exact version.

## File Layout

```
terraform-aws-apigateway-v2/
├── variables.tf      # 43 inputs, all optional (upstream shape)
├── main.tf           # all resources (legacy name — resources.tf is the standard)
├── migrations.tf     # moved {} blocks from the upstream v5 refactor
├── outputs.tf        # ids, ARNs, endpoints, and the routes/integrations/vpc_links maps
├── versions.tf       # required_version + required_providers
├── wrappers/         # upstream for_each wrapper
├── examples/         # complete-http, vpc-link-http, websocket
├── CHANGELOG.md      # upstream changelog (ends at 5.2.1)
├── UPGRADE-5.0.md    # upstream v4 → v5 migration notes
└── README.md         # upstream README (source line still names the public module)
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `create` | `bool` | `true` | Create any resources at all. |
| `tags` | `map(string)` | `{}` | Tags for all API Gateway resources. |
| `name` | `string` | `""` | API name (≤ 128 chars). |
| `protocol_type` | `string` | `"HTTP"` | `HTTP` or `WEBSOCKET`. |
| `description` | `string` | `null` | API description (≤ 1024 chars). |
| `api_version` | `string` | `null` | Version identifier for the API. |
| `body` | `string` | `null` | OpenAPI spec defining routes/integrations (HTTP). |
| `cors_configuration` | `object` | `null` | CORS settings (HTTP). |
| `credentials_arn` | `string` | `null` | Quick-create integration credentials (HTTP). |
| `disable_execute_api_endpoint` | `bool` | `null` | Disable the default execute-api endpoint. |
| `fail_on_warnings` | `bool` | `null` | Fail on OpenAPI import warnings (HTTP). |
| `api_key_selection_expression` | `string` | `null` | API key selection expression (WebSocket). |
| `route_key` | `string` | `null` | Quick-create route key (HTTP). |
| `route_selection_expression` | `string` | `null` | Route selection expression. |
| `target` | `string` | `null` | Quick-create integration target (HTTP). |
| `api_mapping_key` | `string` | `null` | API mapping key for the default stage. |
| `additional_stage_api_mappings` | `map(object)` | `{}` | Extra API mappings for the default stage. |
| `authorizers` | `map(object)` | `{}` | Authorizers to create, keyed by name. |
| `create_domain_name` | `bool` | `true` | Create the custom domain name. |
| `domain_name` | `string` | `""` | Custom domain name. |
| `hosted_zone_name` | `string` | `null` | Hosted zone for the domain records. |
| `domain_name_certificate_arn` | `string` | `null` | ACM certificate for the domain. |
| `domain_name_ownership_verification_certificate_arn` | `string` | `null` | Ownership-verification certificate ARN. |
| `mutual_tls_authentication` | `map(string)` | `{}` | Mutual TLS configuration. |
| `create_domain_records` | `bool` | `true` | Create Route 53 records for the domain. |
| `subdomains` | `list(string)` | `[]` | Extra subdomains to record. |
| `subdomain_record_types` | `list(string)` | `["A", "AAAA"]` | Record types for the domain/subdomains. |
| `create_certificate` | `bool` | `true` | Create an ACM certificate for the domain. |
| `create_routes_and_integrations` | `bool` | `true` | Create routes and integrations. |
| `routes` | `map(object)` | `{}` | Routes keyed by route key, each with an inline `integration`. |
| `integrations` | `map(object)` | `{}` | Standalone integrations keyed by name. |
| `create_stage` | `bool` | `true` | Create the default stage. |
| `stage_name` | `string` | `"$default"` | Stage name. |
| `stage_description` | `string` | `null` | Stage description. |
| `stage_access_log_settings` | `object` | `{}` | Access-log destination and format. |
| `stage_client_certificate_id` | `string` | `null` | Client certificate (WebSocket). |
| `stage_default_route_settings` | `object` | `{}` | Default route settings (throttling, logging). |
| `stage_route_settings` | `map(object)` | `{}` | Per-route stage settings. |
| `stage_variables` | `map(string)` | `{}` | Stage variables. |
| `stage_tags` | `map(string)` | `{}` | Stage tags. |
| `deploy_stage` | `bool` | `true` | Deploy the stage (HTTP auto-deploys). |
| `vpc_links` | `map(object)` | `{}` | VPC links to create, keyed by name. |
| `vpc_link_tags` | `map(string)` | `{}` | Tags for VPC links. |

## Outputs

| Name | Description |
|---|---|
| `api_id`, `api_arn`, `api_execution_arn`, `api_endpoint` | The API and its invoke endpoint. |
| `authorizers` | Map of created authorizers. |
| `domain_name_id`, `domain_name_arn`, `domain_name_configuration`, `domain_name_target_domain_name`, `domain_name_hosted_zone_id`, `domain_name_api_mapping_selection_expression` | Custom domain details for DNS aliasing. |
| `acm_certificate_arn` | Certificate created when `create_certificate`. |
| `integrations`, `routes` | Maps of created integrations and routes. |
| `stage_id`, `stage_arn`, `stage_domain_name`, `stage_execution_arn`, `stage_invoke_url` | Default stage details. |
| `stage_access_logs_cloudwatch_log_group_name`, `…_arn` | Access-log group. |
| `vpc_links` | Map of created VPC links. |

## Examples

- `examples/complete-http` — HTTP API with routes, authorizer, custom domain, and access logs.
- `examples/vpc-link-http` — HTTP API integrating with private resources through a VPC link.
- `examples/websocket` — WebSocket API with route responses.

## Validate Changes Locally

- Run `terraform fmt` before opening a PR (always — CI may fail otherwise).
- From the module dir: `terraform init -upgrade=false`.
- Run `terraform validate`.
- **Do not run `terraform plan` or `terraform apply` locally** — modules
  don't hold state on their own; that happens in the consumer stack.

## Publishing a New Version

1. Make the changes; run `terraform fmt` + `terraform validate` (and
   `terraform test` only if a `tests/` directory exists).
2. Pick the version by semver: adding a **required** input, or renaming or
   removing an output, is a **breaking change → major bump**; a new optional
   input → minor; a fix → patch.
3. Update `README.md` (and `CHANGELOG.md` if the module keeps one).
4. Tag and push **that one tag**: `git tag vX.Y.Z && git push origin vX.Y.Z`.
5. HCP Registry auto-publishes from the tag; bump consumers' `version` pins to
   the exact, `v`-stripped value (`3.1.0`, not `v3.1.0`).

## Conventions & Naming

House style and module conventions load automatically from the
`harri-tf-house-style` and `harri-tf-modules` rules whenever a `.tf` file in this
module is edited — they are not repeated here.

### Project naming patterns

- API name: `{env}-{service}` in Harri consumers; the default stage is `$default`.
- Custom domains are the FQDN (`gateway.harriprep.com`); `subdomains` are
  recorded as A and AAAA aliases by default.
- Every resource group is gated by its `create_*` flag — pass an existing
  `domain_name` with `create_domain_name = false` to attach to a shared domain.
- Consumers pin `1.0.0` (TerraformAPIGateway) and `1.0.1` (the microservice
  module); the version shown above is the highest in use. Upstream tags
  (`v5.x`) do not correspond to the Harri registry versions.
