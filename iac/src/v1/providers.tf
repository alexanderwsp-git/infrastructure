terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "mexp-terraform-state-991795763909"
    key            = "webapp-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mexp-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "postgresql" {
  alias           = "lanapp"
  host            = aws_db_instance.postgres_awsp.address
  port            = 5432
  database        = "lanappdb"
  username        = var.db_user_lanapp
  password        = var.db_password_lanapp
  sslmode         = "require"
  connect_timeout = 15
}

