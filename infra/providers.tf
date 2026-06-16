terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

