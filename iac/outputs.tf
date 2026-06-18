# =============================================================================
# Cognito outputs — Lanapp ECS env
# =============================================================================

output "cognito_user_pool_id" {
  description = "Lanapp Cognito User Pool ID"
  value       = aws_cognito_user_pool.lanapp.id
}

output "cognito_user_pool_arn" {
  description = "Lanapp Cognito User Pool ARN"
  value       = aws_cognito_user_pool.lanapp.arn
}

output "cognito_issuer_url" {
  description = "JWT issuer URL for lanapp API token validation"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.lanapp.id}"
}

output "cognito_domain" {
  description = "Cognito hosted UI domain prefix"
  value       = aws_cognito_user_pool_domain.lanapp.domain
}

output "cognito_client_id" {
  description = "Lanapp app client ID (UI BFF + API JWT validation)"
  value       = aws_cognito_user_pool_client.lanapp.id
}

output "cognito_client_secret" {
  description = "Lanapp app client secret — sensitive; use in ECS .env_frontend"
  value       = aws_cognito_user_pool_client.lanapp.client_secret
  sensitive   = true
}

output "cognito_groups" {
  description = "Lanapp RBAC groups"
  value       = keys(local.cognito_groups)
}

output "lanapp_front_task_role_arn" {
  description = "ECS task role for lanapp-ui (Cognito BFF)"
  value       = aws_iam_role.lanapp_front_task_role.arn
}
