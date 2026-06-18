output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 bucket for Terraform remote state"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table for Terraform state locking"
}

output "backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "webapp-infra/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
  description = "Backend settings (configured inline in infra/providers.tf)"
}
