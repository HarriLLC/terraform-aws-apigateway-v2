# CLAUDE.md

`terraform-aws-apigateway-v2` — a reusable Harri Terraform **module**, published to the HCP
private registry.

## What This Module Provisions

- `aws_apigatewayv2_api` (HTTP or WebSocket, `protocol_type`), gated by `create`.
- `aws_apigatewayv2_route` / `_integration` (plus `_route_response` / `_integration_response`) per `routes` / `integrations` entry, and `aws_apigatewayv2_authorizer` per `authorizers` entry.
- `aws_apigatewayv2_stage` (`create_stage`), `aws_apigatewayv2_deployment` for WebSocket APIs only (`deploy_stage`), and an `aws_cloudwatch_log_group` for access logs unless `stage_access_log_settings.create_log_group = false`.
- `aws_apigatewayv2_domain_name` + `aws_apigatewayv2_api_mapping` (`create_domain_name`), Route 53 alias records per domain/subdomain × `subdomain_record_types` (`create_domain_records`), and an ACM certificate via `terraform-aws-modules/acm` (`create_certificate` **and** `create_domain_records`, public zones only).
- `aws_apigatewayv2_vpc_link` per `vpc_links` entry; every group sits behind a `create_*` toggle so a caller can reuse an existing domain or stage.

## Registry Source

```hcl
module "apigateway_v2" {
  source  = "app.terraform.io/harri/apigateway-v2/aws"
  version = "x.y.z"   # pin the current published version

  # no required inputs — set only what differs from the defaults
}
```

> Take the current published version from the HCP private registry, or from the
> `version` pinned beside this `source` in a consumer's `common/resources.tf`.
> Consumers pin an exact version; ranges are never allowed.

## Required Versions

Read them from **`versions.tf`**: `required_version` for Terraform core, and each
`required_providers` entry for the providers. They are not repeated here, so this
guide cannot go stale when they change.

## File Layout

```
terraform-aws-apigateway-v2/
├── variables.tf             # inputs
├── main.tf                  # the AWS resources this module creates
├── migrations.tf            # moved blocks from the upstream v4 → v5 refactor
├── outputs.tf               # what consumers can wire
├── versions.tf              # Terraform + provider constraints
├── README.md                # usage example, inputs/outputs reference
├── CHANGELOG.md             # release notes
├── LICENSE                  # upstream licence
├── examples/complete-http/  # standalone example callers
├── examples/vpc-link-http/  # standalone example callers
├── examples/websocket/      # standalone example callers
└── wrappers/                # for_each wrapper for calling the module many times
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `create` | `bool` | `true` | Controls if resources should be created |
| `region` | `string` | `null` | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration |
| `tags` | `map(string)` | `{}` | A mapping of tags to assign to API gateway resources |
| `api_key_selection_expression` | `string` | `null` | An API key selection expression. Valid values: `$context.authorizer.usageIdentifierKey`, `$request.header.x-api-key`. Defaults to `$request.header.x-api-key`. Applicable for WebSocket APIs |
| `cors_configuration` | `object({…})` | `null` | The cross-origin resource sharing (CORS) configuration. Applicable for HTTP APIs |
| `credentials_arn` | `string` | `null` | Part of quick create. Specifies any credentials required for the integration. Applicable for HTTP APIs |
| `description` | `string` | `null` | The description of the API. Must be less than or equal to 1024 characters in length |
| `disable_execute_api_endpoint` | `bool` | `null` | Whether clients can invoke the API by using the default execute-api endpoint. By default, clients can invoke the API with the default `{api_id}.execute-api.{region}.amazonaws.com endpoint`. To require that clients use a custom domain name to invoke the API, disable the default endpoint |
| `fail_on_warnings` | `bool` | `null` | Whether warnings should return an error while API Gateway is creating or updating the resource using an OpenAPI specification. Defaults to `false`. Applicable for HTTP APIs |
| `ip_address_type` | `string` | `null` | The IP address types that can invoke the API. Valid values: ipv4, dualstack. Use ipv4 to allow only IPv4 addresses to invoke your API, or use dualstack to allow both IPv4 and IPv6 addresses to invoke your API. Defaults to ipv4. |
| `name` | `string` | `""` | The name of the API. Must be less than or equal to 128 characters in length |
| `body` | `string` | `null` | An OpenAPI specification that defines the set of routes and integrations to create as part of the HTTP APIs. Supported only for HTTP APIs |
| `protocol_type` | `string` | `"HTTP"` | The API protocol. Valid values: `HTTP`, `WEBSOCKET` |
| `route_key` | `string` | `null` | Part of quick create. Specifies any route key. Applicable for HTTP APIs |
| `route_selection_expression` | `string` | `null` | The route selection expression for the API. Defaults to `$request.method $request.path` |
| `target` | `string` | `null` | Part of quick create. Quick create produces an API with an integration, a default catch-all route, and a default stage which is configured to automatically deploy changes. For HTTP integrations, specify a fully qualified URL. For Lambda integrations, specify a function ARN. The type of the integration will be HTTP_PROXY or AWS_PROXY, respectively. Applicable for HTTP APIs |
| `api_version` | `string` | `null` | A version identifier for the API. Must be between 1 and 64 characters in length |
| `api_mapping_key` | `string` | `null` | The [API mapping key](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-mapping-template-reference.html) |
| `additional_stage_api_mappings` | `map(object({…}))` | `{}` | Additional mapping for default stage |
| `authorizers` | `map(object({…}))` | `{}` | Map of API gateway authorizers to create |
| `create_domain_name` | `bool` | `true` | Whether to create API domain name resource |
| `domain_name` | `string` | `""` | The domain name to use for API gateway |
| `hosted_zone_name` | `string` | `null` | Optional domain name of the Hosted Zone where the domain should be created |
| `private_zone` | `bool` | `false` | Indicates the hosted zone being looked up is private.  Certificate validation will fail if this is set to true. |
| `domain_name_certificate_arn` | `string` | `null` | The ARN of an AWS-managed certificate that will be used by the endpoint for the domain name. AWS Certificate Manager is the only supported source |
| `domain_name_ownership_verification_certificate_arn` | `string` | `null` | ARN of the AWS-issued certificate used to validate custom domain ownership (when certificate_arn is issued via an ACM Private CA or mutual_tls_authentication is configured with an ACM-imported certificate.) |
| `mutual_tls_authentication` | `map(string)` | `{}` | The mutual TLS authentication configuration for the domain name |
| `create_domain_records` | `bool` | `true` | Whether to create Route53 records for the domain name |
| `subdomains` | `list(string)` | `[]` | An optional list of subdomains to use for API gateway |
| `subdomain_record_types` | `list(string)` | `["A", "AAAA"]` | A list of record types to create for the subdomain(s) |
| `create_certificate` | `bool` | `true` | Whether to create a certificate for the domain.  Since certificate validate only works on public domains, this will be ignore if `private_zone` is set to `true` |
| `create_routes_and_integrations` | `bool` | `true` | Whether to create routes and integrations resources |
| `routes` | `map(object({…}))` | `{}` | Map of API gateway routes with integrations |
| `integrations` | `map(object({…}))` | `{}` | Map of API gateway integrations |
| `create_stage` | `bool` | `true` | Whether to create default stage |
| `stage_access_log_settings` | `object({…})` | `{}` | Settings for logging access in this stage. Use the aws_api_gateway_account resource to configure [permissions for CloudWatch Logging](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#set-up-access-logging-permissions) |
| `stage_client_certificate_id` | `string` | `null` | The identifier of a client certificate for the stage. Use the `aws_api_gateway_client_certificate` resource to configure a client certificate. Supported only for WebSocket APIs |
| `stage_default_route_settings` | `object({…})` | `{}` | The default route settings for the stage |
| `stage_route_settings` | `map(object({…}))` | `{}` | Route settings for the stage |
| `stage_description` | `string` | `null` | The description for the stage. Must be less than or equal to 1024 characters in length |
| `stage_name` | `string` | `"$default"` | The name of the stage. Must be between 1 and 128 characters in length |
| `stage_variables` | `map(string)` | `{}` | A map that defines the stage variables for the stage |
| `stage_tags` | `map(string)` | `{}` | A mapping of tags to assign to the stage resource |
| `deploy_stage` | `bool` | `true` | Whether to deploy the stage. `HTTP` APIs are auto-deployed by default |
| `vpc_links` | `map(object({…}))` | `{}` | Map of VPC Link definitions to create |
| `vpc_link_tags` | `map(string)` | `{}` | A map of tags to add to the VPC Links created |

## Outputs

| Name | Description |
|---|---|
| `api_id` | The API identifier |
| `api_endpoint` | URI of the API, of the form `https://{api-id}.execute-api.{region}.amazonaws.com` for HTTP APIs and `wss://{api-id}.execute-api.{region}.amazonaws.com` for WebSocket APIs |
| `api_arn` | The ARN of the API |
| `api_execution_arn` | The ARN prefix to be used in an `aws_lambda_permission`'s `source_arn` attribute or in an `aws_iam_policy` to authorize access to the `@connections` API |
| `authorizers` | Map of API Gateway Authorizer(s) created and their attributes |
| `domain_name_id` | The domain name identifier |
| `domain_name_arn` | The ARN of the domain name |
| `domain_name_api_mapping_selection_expression` | The API mapping selection expression for the domain name |
| `domain_name_configuration` | The domain name configuration |
| `domain_name_target_domain_name` | The target domain name |
| `domain_name_hosted_zone_id` | The Amazon Route 53 Hosted Zone ID of the endpoint |
| `acm_certificate_arn` | The ARN of the certificate |
| `integrations` | Map of the integrations created and their attributes |
| `routes` | Map of the routes created and their attributes |
| `stage_id` | The stage identifier |
| `stage_domain_name` | Domain name of the stage (useful for CloudFront distribution) |
| `stage_arn` | The stage ARN |
| `stage_execution_arn` | The ARN prefix to be used in an aws_lambda_permission's source_arn attribute or in an aws_iam_policy to authorize access to the @connections API |
| `stage_invoke_url` | The URL to invoke the API pointing to the stage |
| `stage_access_logs_cloudwatch_log_group_name` | Name of cloudwatch log group created |
| `stage_access_logs_cloudwatch_log_group_arn` | Arn of cloudwatch log group created |
| `vpc_links` | Map of VPC links created and their attributes |

## Examples

- `examples/complete-http` — an HTTP API with every feature enabled
- `examples/vpc-link-http` — an HTTP API reaching private targets through a VPC link
- `examples/websocket` — a WebSocket API

## Constraints

- The ACM certificate is created only when `create_domain_name`,
  `create_certificate` and `create_domain_records` are all `true` (and
  `private_zone = false`). With `create_domain_records = false`, set
  `create_certificate = false` and pass `domain_name_certificate_arn` —
  otherwise the domain name is given the empty certificate ARN of an ACM module
  that created nothing.
- Changing `protocol_type` replaces the API, and every route, integration,
  authorizer, stage and mapping attached to it.
- Changing `domain_name` replaces the custom domain, its API mapping(s), the
  Route 53 records and the ACM certificate.
- This clone also tracks the `upstream` remote, so it holds upstream's release
  tags — never `git push --tags`; it would push them to `origin`, where HCP
  publishes every tag as a registry version.

## Conventions & Naming

### Project naming patterns

- API name: `{env}-{service}` in Harri consumers (the microservice module passes `${var.environment}-${var.microservice.name}`); the default stage is `$default`.
- Custom domains are the FQDN (`api.example.com`); `subdomains` are
  recorded as A and AAAA aliases by default.
- Every resource group is gated by its `create_*` flag — pass an existing
  `domain_name` with `create_domain_name = false` to attach to a shared domain.
- Consumers are the API Gateway stack and the microservice module; each pins its
  own exact version beside the `source` in its own config. Upstream tags do not
  correspond to the Harri registry versions.
