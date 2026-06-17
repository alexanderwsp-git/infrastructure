# =============================================================================
# Cognito outputs — use in ECS .env files per app
# =============================================================================

output "cognito_user_pool_id" {
  description = "Shared Myxperiences Cognito User Pool ID"
  value       = aws_cognito_user_pool.mexp.id
}

output "cognito_user_pool_arn" {
  description = "Shared Myxperiences Cognito User Pool ARN"
  value       = aws_cognito_user_pool.mexp.arn
}

output "cognito_issuer_url" {
  description = "JWT issuer URL for token validation"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.mexp.id}"
}

output "cognito_domain" {
  description = "Cognito hosted UI domain prefix"
  value       = aws_cognito_user_pool_domain.mexp.domain
}

output "cognito_client_ids" {
  description = "App client IDs (map: lanapp, admin, myxperiences)"
  value       = { for k, v in aws_cognito_user_pool_client.apps : k => v.id }
}

output "cognito_client_secrets" {
  description = "App client secrets — sensitive; store in SSM/Secrets Manager for ECS"
  value       = { for k, v in aws_cognito_user_pool_client.apps : k => v.client_secret }
  sensitive   = true
}

output "cognito_groups" {
  description = "Available group names for RBAC"
  value       = keys(local.cognito_groups)
}

output "lanapp_front_task_role_arn" {
  description = "ECS task role for lanapp-ui (Cognito BFF)"
  value       = aws_iam_role.lanapp_front_task_role.arn
}
