data "aws_route53_zone" "primary" {
  zone_id = var.hosted_zone_id
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags_base
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in tolist(aws_acm_certificate.cert.domain_validation_options) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_lb" "shared_alb" {
  name               = "mexp-shared-apps-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = var.tags_base
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.shared_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 - Subdominio No Encontrado"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.shared_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# =================================================================
# COMENTADO PARA PROTEGER PRODUCCIÓN ACTUAL (APP 1 - MYXPERIENCES)
# =================================================================
# resource "aws_lb_listener_rule" "myxperiences_front" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 10
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.myxperiences_front_tg.arn
#   }
#   condition {
#     host_header { values = [var.domain_name] }
#   }
# }
#
# resource "aws_lb_listener_rule" "myxperiences_back" {
#   listener_arn = aws_lb_listener.https.arn
#   priority     = 20
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.myxperiences_back_tg.arn
#   }
#   condition {
#     host_header { values = ["api.${var.domain_name}"] }
#   }
# }
#
# resource "aws_route53_record" "myxperiences_root_dns" {
#   zone_id = data.aws_route53_zone.primary.zone_id
#   name    = var.domain_name
#   type    = "A"
#   alias {
#     name                   = aws_lb.shared_alb.dns_name
#     zone_id                = aws_lb.shared_alb.zone_id
#     evaluate_target_health = true
#   }
# }
#
# resource "aws_route53_record" "myxperiences_api_dns" {
#   zone_id = data.aws_route53_zone.primary.zone_id
#   name    = "api.${var.domain_name}"
#   type    = "A"
#   alias {
#     name                   = aws_lb.shared_alb.dns_name
#     zone_id                = aws_lb.shared_alb.zone_id
#     evaluate_target_health = true
#   }
# }

# =================================================================
# ACTIVOS (APP 2 Y APP 3 - LANAPP Y ADMIN)
# =================================================================

resource "aws_lb_listener_rule" "lanapp_front" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lanapp_front_tg.arn
  }

  condition {
    host_header {
      values = ["lanapp.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "lanapp_back" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lanapp_back_tg.arn
  }

  condition {
    host_header {
      values = ["lanapp-api.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "admin_front" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_front_tg.arn
  }

  condition {
    host_header {
      values = ["admin.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "admin_back" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 60

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_back_tg.arn
  }

  condition {
    host_header {
      values = ["admin-api.${var.domain_name}"]
    }
  }
}

resource "aws_route53_record" "subdomains_dns" {
  for_each = toset(["lanapp", "lanapp-api", "admin", "admin-api"])

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.shared_alb.dns_name
    zone_id                = aws_lb.shared_alb.zone_id
    evaluate_target_health = true
  }
}
