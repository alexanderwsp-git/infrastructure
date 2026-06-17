# =============================================================================
# Shared Cognito User Pool — Myxperiences suite (lanapp, admin, myxperiences)
# One directory of users; separate app clients per product; groups per app+role.
# =============================================================================

locals {
  cognito_pool_name = "mexp-myxperiences-users"

  # App clients: each ECS frontend BFF uses its own client (confidential + secret).
  cognito_apps = {
    lanapp = {
      name = "mexp-lanapp"
    }
    admin = {
      name = "mexp-admin"
    }
    myxperiences = {
      name = "mexp-myxperiences"
    }
  }

  # Groups: <app>_<role> — assign users to one or more groups across apps.
  cognito_groups = {
    platform_admin = { description = "Full platform access across all suite apps" }

    lanapp_admin       = { description = "Lanapp — Administrador" }
    lanapp_veterinario = { description = "Lanapp — Veterinario" }
    lanapp_operario    = { description = "Lanapp — Operario" }

    admin_admin    = { description = "Admin panel — Administrador" }
    admin_operator = { description = "Admin panel — Operador" }

    myxperiences_admin = { description = "Myxperiences — Administrador" }
    myxperiences_user  = { description = "Myxperiences — Usuario" }
  }
}

resource "aws_cognito_user_pool" "mexp" {
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
    app  = "suite"
  })
}

resource "aws_cognito_user_pool_domain" "mexp" {
  domain       = "mexp-${replace(var.domain_name, ".", "-")}"
  user_pool_id = aws_cognito_user_pool.mexp.id
}

resource "aws_cognito_user_pool_client" "apps" {
  for_each = local.cognito_apps

  name         = each.value.name
  user_pool_id = aws_cognito_user_pool.mexp.id

  generate_secret             = true
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation     = true
  refresh_token_validity      = 30
  access_token_validity       = 1
  id_token_validity           = 1

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

resource "aws_cognito_user_group" "groups" {
  for_each = local.cognito_groups

  name         = each.key
  user_pool_id = aws_cognito_user_pool.mexp.id
  description  = each.value.description
}

# =============================================================================
# IAM — ECS task roles that run Cognito BFF (admin user APIs)
# =============================================================================

data "aws_iam_policy_document" "cognito_idp_admin" {
  statement {
    sid    = "CognitoUserPoolAdmin"
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
    resources = [aws_cognito_user_pool.mexp.arn]
  }
}

resource "aws_iam_policy" "cognito_idp_admin" {
  name        = "mexp-cognito-idp-admin"
  description = "Cognito User Pool admin + auth flows for suite app BFFs"
  policy      = data.aws_iam_policy_document.cognito_idp_admin.json

  tags = merge(var.tags_base, { app = "suite" })
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
  policy_arn = aws_iam_policy.cognito_idp_admin.arn
}

resource "aws_iam_role" "admin_front_task_role" {
  name = "mexp-admin-front-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags_base, { app = "admin" })
}

resource "aws_iam_role_policy_attachment" "admin_front_cognito" {
  role       = aws_iam_role.admin_front_task_role.name
  policy_arn = aws_iam_policy.cognito_idp_admin.arn
}

resource "aws_iam_role" "myxperiences_front_task_role" {
  name = "mexp-myxperiences-front-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_iam_role_policy_attachment" "myxperiences_front_cognito" {
  role       = aws_iam_role.myxperiences_front_task_role.name
  policy_arn = aws_iam_policy.cognito_idp_admin.arn
}
