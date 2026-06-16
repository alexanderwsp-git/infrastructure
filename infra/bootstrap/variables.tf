variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for the state bucket and lock table"
}

variable "state_bucket_name" {
  type        = string
  default     = "mexp-terraform-state-991795763909"
  description = "Globally unique S3 bucket name for Terraform remote state"
}

variable "lock_table_name" {
  type        = string
  default     = "mexp-terraform-locks"
  description = "DynamoDB table name for Terraform state locking"
}

variable "tags_base" {
  type = map(string)
  default = {
    creator = "terraform"
    name    = "myxperiences"
  }
}
