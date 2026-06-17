# Target Groups del ALB
resource "aws_lb_target_group" "myxperiences_front_tg" {
  name        = "mexp-myxperiences-front-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/" }
  tags = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_lb_target_group" "myxperiences_back_tg" {
  name        = "mexp-myxperiences-back-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/api" }
  tags = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_lb_target_group" "lanapp_front_tg" {
  name        = "mexp-lanapp-front-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = merge(var.tags_base, { app = "awsp" })
}

resource "aws_lb_target_group" "lanapp_back_tg" {
  name        = "mexp-lanapp-back-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/api/v1/lanapp/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
  tags = merge(var.tags_base, { app = "awsp" })
}

resource "aws_lb_target_group" "admin_front_tg" {
  name        = "mexp-admin-front-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/" }
  tags = merge(var.tags_base, { app = "admin" })
}

resource "aws_lb_target_group" "admin_back_tg" {
  name        = "mexp-admin-back-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/api/health" }
  tags = merge(var.tags_base, { app = "admin" })
}

# Repositorios ECR (Indentacion limpia sin punto y coma)
resource "aws_ecr_repository" "myxperiences_front" {
  name = "mexp-myxperiences-front"
  tags = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_ecr_repository" "myxperiences_backend" {
  name = "mexp-myxperiences-back"
  tags = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_ecr_repository" "lanapp_front" {
  name = "mexp-lanapp-front"
  tags = merge(var.tags_base, { app = "awsp" })
}

resource "aws_ecr_repository" "lanapp_back" {
  name = "mexp-lanapp-back"
  tags = merge(var.tags_base, { app = "awsp" })
}

resource "aws_ecr_repository" "admin_front" {
  name = "mexp-admin-front"
  tags = merge(var.tags_base, { app = "admin" })
}

resource "aws_ecr_repository" "admin_back" {
  name = "mexp-admin-back"
  tags = merge(var.tags_base, { app = "admin" })
}

# Buckets S3 Privados
resource "aws_s3_bucket" "myxperiences_bucket" {
  bucket        = "mexp-imagenes-myxperiences-unique-id"
  force_destroy = true
  tags          = merge(var.tags_base, { app = "xperiences" })
}

resource "aws_s3_bucket" "lanapp_bucket" {
  bucket        = "mexp-imagenes-lanapp-unique-id"
  force_destroy = true
  tags          = merge(var.tags_base, { app = "awsp" })
}

resource "aws_s3_bucket" "admin_bucket" {
  bucket        = "mexp-imagenes-admin-unique-id"
  force_destroy = true
  tags          = merge(var.tags_base, { app = "admin" })
}

resource "aws_ecs_cluster" "main_cluster" {
  name = "mexp-apps-shared-cluster"
  tags = var.tags_base
}

# cloudwatch log groups

# Grupo de Logs para la App de Viajes (Myxperiences)
resource "aws_cloudwatch_log_group" "myxperiences_back_logs" {
  name              = "/ecs/mexp-myxperiences-back"
  retention_in_days = 7 # Borra logs viejos de más de 7 días para ahorrar dinero

  tags = merge(var.tags_base, {
    app = "xperiences"
  })
}

# Grupo de Logs para la App de Ovejas (Lanapp)
resource "aws_cloudwatch_log_group" "lanapp_back_logs" {
  name              = "/ecs/mexp-lanapp-back"
  retention_in_days = 7

  tags = merge(var.tags_base, {
    app = "awsp"
  })
}

resource "aws_cloudwatch_log_group" "lanapp_front_logs" {
  name              = "/ecs/mexp-lanapp-front"
  retention_in_days = 7

  tags = merge(var.tags_base, {
    app = "awsp"
  })
}

# Grupo de Logs para la App de Administración (Admin)
resource "aws_cloudwatch_log_group" "admin_back_logs" {
  name              = "/ecs/mexp-admin-back"
  retention_in_days = 7

  tags = merge(var.tags_base, {
    app = "admin"
  })
}

resource "aws_cloudwatch_log_group" "admin_front_logs" {
  name              = "/ecs/mexp-admin-front"
  retention_in_days = 7

  tags = merge(var.tags_base, {
    app = "admin"
  })
}

# =================================================================
# ROL DE TAREA (Task Role) PARA ADMIN-BACK
# =================================================================

resource "aws_iam_role" "admin_task_role" {
  name = "mexp-admin-back-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
EOF

  tags = merge(var.tags_base, { app = "admin" })
}

resource "aws_iam_policy" "admin_s3_policy" {
  name        = "mexp-admin-s3-policy"
  description = "Permite al contenedor admin conectarse a su bucket de S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.admin_bucket.arn,
        "${aws_s3_bucket.admin_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_s3_attach" {
  role       = aws_iam_role.admin_task_role.name
  policy_arn = aws_iam_policy.admin_s3_policy.arn
}

# =================================================================
#  ROL DE TAREA (Task Role) PARA LANAPP-BACK
# =================================================================

resource "aws_iam_role" "lanapp_task_role" {
  name = "mexp-lanapp-back-task-role" # 👈 El mismo nombre exacto que busca tu JSON

  # Aquí está la relación de confianza que le faltaba a AWS
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
EOF

  tags = merge(var.tags_base, { app = "awsp" })
}

# Permiso básico para que tu NestJS pueda subir y leer imágenes de tu S3
resource "aws_iam_policy" "lanapp_s3_policy" {
  name        = "mexp-lanapp-s3-policy"
  description = "Permite al contenedor de NestJS conectarse a su bucket de S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.lanapp_bucket.arn,
        "${aws_s3_bucket.lanapp_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lanapp_s3_attach" {
  role       = aws_iam_role.lanapp_task_role.name
  policy_arn = aws_iam_policy.lanapp_s3_policy.arn
}

# =================================================================
# 12. ROL DE EJECUCIÓN DE ECS (Corregido con bloque de datos nativo)
# =================================================================

# Genera la estructura JSON de confianza de forma nativa en Terraform
data "aws_iam_policy_document" "ecs_execution_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Crea el rol de ejecucion vinculando la politica de arriba
resource "aws_iam_role" "ecs_execution_role_mexp" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_trust.json

  tags = var.tags_base
}

# Adjunta la politica oficial de AWS para descargar de ECR y subir logs
resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role_mexp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
