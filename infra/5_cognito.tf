# =============================================================================
# Cognito User Pool — Lanapp only
# Admin invite + groups: lanapp_admin, lanapp_veterinario, lanapp_operario
# =============================================================================

locals {
  cognito_pool_name = "mexp-lanapp-users"

  cognito_groups = {
    lanapp_admin       = { description = "Lanapp — Administrador" }
    lanapp_veterinario = { description = "Lanapp — Veterinario" }
    lanapp_operario    = { description = "Lanapp — Operario" }
  }
}

resource "aws_cognito_user_pool" "lanapp" {
  name = local.cognito_pool_name

  user_pool_tier = "LITE"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    name                = "preferred_username"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  tags = merge(var.tags_base, {
    Name = local.cognito_pool_name
    app  = "lanapp"
  })
}

resource "aws_cognito_user_pool_domain" "lanapp" {
  domain       = "mexp-lanapp-${replace(var.domain_name, ".", "-")}"
  user_pool_id = aws_cognito_user_pool.lanapp.id
}

resource "aws_cognito_user_pool_client" "lanapp" {
  name         = "mexp-lanapp"
  user_pool_id = aws_cognito_user_pool.lanapp.id

  generate_secret               = true
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
  refresh_token_validity        = 30
  access_token_validity         = 1
  id_token_validity             = 1

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  read_attributes = [
    "email",
    "email_verified",
    "preferred_username",
  ]

  write_attributes = [
    "email",
    "preferred_username",
  ]
}

resource "aws_cognito_user_group" "lanapp" {
  for_each = local.cognito_groups

  name         = each.key
  user_pool_id = aws_cognito_user_pool.lanapp.id
  description  = each.value.description
}

# =============================================================================
# IAM — lanapp-ui ECS task role (Cognito BFF)
# =============================================================================

data "aws_iam_policy_document" "cognito_idp_lanapp" {
  statement {
    sid    = "CognitoUserPoolLanapp"
    effect = "Allow"
    actions = [
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminDisableUser",
      "cognito-idp:AdminEnableUser",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminInitiateAuth",
      "cognito-idp:AdminListGroupsForUser",
      "cognito-idp:AdminRemoveUserFromGroup",
      "cognito-idp:AdminSetUserPassword",
      "cognito-idp:AdminUpdateUserAttributes",
      "cognito-idp:AdminUserGlobalSignOut",
      "cognito-idp:ForgotPassword",
      "cognito-idp:ConfirmForgotPassword",
      "cognito-idp:GlobalSignOut",
      "cognito-idp:GetUser",
      "cognito-idp:ListUsers",
      "cognito-idp:RespondToAuthChallenge",
    ]
    resources = [aws_cognito_user_pool.lanapp.arn]
  }
}

resource "aws_iam_policy" "cognito_idp_lanapp" {
  name        = "mexp-cognito-idp-lanapp"
  description = "Cognito User Pool admin + auth flows for lanapp-ui BFF"
  policy      = data.aws_iam_policy_document.cognito_idp_lanapp.json

  tags = merge(var.tags_base, { app = "lanapp" })
}

resource "aws_iam_role" "lanapp_front_task_role" {
  name = "mexp-lanapp-front-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags_base, { app = "lanapp" })
}

resource "aws_iam_role_policy_attachment" "lanapp_front_cognito" {
  role       = aws_iam_role.lanapp_front_task_role.name
  policy_arn = aws_iam_policy.cognito_idp_lanapp.arn
}
