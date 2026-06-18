# =============================================================================
# Cognito outputs — suite + lanapp
# =============================================================================

# Suite (shared user pool + domain)

output "cognito_user_pool_id" {
  description = "Suite Cognito User Pool ID"
  value       = aws_cognito_user_pool.cognito.id
}

output "cognito_user_pool_arn" {
  description = "Suite Cognito User Pool ARN"
  value       = aws_cognito_user_pool.cognito.arn
}

output "cognito_issuer_url" {
  description = "JWT issuer URL for API token validation"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.cognito.id}"
}

output "cognito_domain" {
  description = "Cognito hosted UI domain prefix (auth-myxperiences-org)"
  value       = aws_cognito_user_pool_domain.cognito.domain
}

# Lanapp app client + groups

output "lanapp_cognito_client_id" {
  description = "Lanapp app client ID (UI BFF + API JWT validation)"
  value       = aws_cognito_user_pool_client.lanapp.id
}

output "lanapp_cognito_client_secret" {
  description = "Lanapp app client secret — sensitive; use in ECS .env_frontend"
  value       = aws_cognito_user_pool_client.lanapp.client_secret
  sensitive   = true
}

output "lanapp_cognito_groups" {
  description = "Lanapp RBAC groups"
  value       = keys(local.lanapp_cognito_groups)
}

output "lanapp_front_task_role_arn" {
  description = "ECS task role for lanapp-ui (Cognito BFF)"
  value       = aws_iam_role.lanapp_front_task_role.arn
}

# Backward-compatible aliases (deprecated — use lanapp_cognito_* outputs)

output "cognito_client_id" {
  description = "Deprecated: use lanapp_cognito_client_id"
  value       = aws_cognito_user_pool_client.lanapp.id
}

output "cognito_client_secret" {
  description = "Deprecated: use lanapp_cognito_client_secret"
  value       = aws_cognito_user_pool_client.lanapp.client_secret
  sensitive   = true
}
