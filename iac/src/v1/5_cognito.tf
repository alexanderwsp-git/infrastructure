# =============================================================================
# Cognito — suite-wide user pool + domain; lanapp app client/groups for now
# =============================================================================

locals {
  cognito_pool_name     = "mexp-myxperiences-users"
  cognito_domain_prefix = "auth-${replace(var.domain_name, ".", "-")}"

  lanapp_cognito_groups = {
    lanapp_admin       = { description = "Lanapp — Administrador" }
    lanapp_veterinario = { description = "Lanapp — Veterinario" }
    lanapp_operario    = { description = "Lanapp — Operario" }
  }

  # Sorted so IAM policy JSON matches AWS after apply (avoids perpetual plan drift).
  cognito_idp_actions = sort([
    "cognito-idp:AdminAddUserToGroup",
    "cognito-idp:AdminCreateUser",
    "cognito-idp:AdminDeleteUser",
    "cognito-idp:AdminDisableUser",
    "cognito-idp:AdminEnableUser",
    "cognito-idp:AdminGetUser",
    "cognito-idp:AdminInitiateAuth",
    "cognito-idp:AdminListGroupsForUser",
    "cognito-idp:AdminRemoveUserFromGroup",
    "cognito-idp:AdminSetUserPassword",
    "cognito-idp:AdminUpdateUserAttributes",
    "cognito-idp:AdminUserGlobalSignOut",
    "cognito-idp:ConfirmForgotPassword",
    "cognito-idp:ForgotPassword",
    "cognito-idp:GetUser",
    "cognito-idp:GlobalSignOut",
    "cognito-idp:ListUsers",
    "cognito-idp:RespondToAuthChallenge",
  ])
}

# State migration from lanapp-prefixed suite resources
moved {
  from = aws_cognito_user_pool.lanapp
  to   = aws_cognito_user_pool.cognito
}

moved {
  from = aws_cognito_user_pool_domain.lanapp
  to   = aws_cognito_user_pool_domain.cognito
}

moved {
  from = data.aws_iam_policy_document.cognito_idp_lanapp
  to   = data.aws_iam_policy_document.cognito_idp
}

moved {
  from = aws_iam_policy.cognito_idp_lanapp
  to   = aws_iam_policy.cognito_idp
}

# -----------------------------------------------------------------------------
# Suite — shared across all apps (lanapp, admin, myxperiences, …)
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool" "cognito" {
  name = local.cognito_pool_name

  # user_pool_tier (LITE/ESSENTIALS/PLUS) requires hashicorp/aws >= 5.83.
  # Omitted here: AWS defaults to ESSENTIALS — same 10k MAU free tier for Lanapp.

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

  # preferred_username is a standard Cognito attribute — do not declare schema {}
  # (causes perpetual drift: AWS returns developer_only_attribute, empty blocks, etc.)

  tags = merge(var.tags_base, {
    Name = local.cognito_pool_name
    app  = "suite"
  })

  lifecycle {
    ignore_changes = [schema]
  }
}

resource "aws_cognito_user_pool_domain" "cognito" {
  domain       = local.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.cognito.id
}

# -----------------------------------------------------------------------------
# Lanapp — app client + RBAC groups
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "lanapp" {
  name         = "mexp-lanapp"
  user_pool_id = aws_cognito_user_pool.cognito.id

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
    "ALLOW_USER_PASSWORD_AUTH",
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
  for_each = local.lanapp_cognito_groups

  name         = each.key
  user_pool_id = aws_cognito_user_pool.cognito.id
  description  = each.value.description
}

# -----------------------------------------------------------------------------
# IAM — shared Cognito policy; lanapp front task role attaches today
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cognito_idp" {
  statement {
    sid       = "CognitoUserPool"
    effect    = "Allow"
    actions   = local.cognito_idp_actions
    resources = [aws_cognito_user_pool.cognito.arn]
  }
}

resource "aws_iam_policy" "cognito_idp" {
  name        = "mexp-cognito-idp"
  description = "Cognito User Pool admin + auth flows for suite app BFFs"
  policy      = data.aws_iam_policy_document.cognito_idp.json

  tags = merge(var.tags_base, { app = "suite" })

  lifecycle {
    ignore_changes = [policy]
  }
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
  policy_arn = aws_iam_policy.cognito_idp.arn
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lanapp_front_ses" {
  statement {
    sid    = "SendInviteEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = [
      "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/${var.domain_name}",
    ]
  }
}

resource "aws_iam_policy" "lanapp_front_ses" {
  name        = "mexp-lanapp-front-ses"
  description = "Send invite emails via SES for Lanapp front BFF"
  policy      = data.aws_iam_policy_document.lanapp_front_ses.json

  tags = merge(var.tags_base, { app = "lanapp" })
}

resource "aws_iam_role_policy_attachment" "lanapp_front_ses" {
  role       = aws_iam_role.lanapp_front_task_role.name
  policy_arn = aws_iam_policy.lanapp_front_ses.arn
}
