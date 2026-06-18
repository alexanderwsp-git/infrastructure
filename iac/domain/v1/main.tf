provider "aws" {
  region = "us-east-1"
}

data "aws_route53_zone" "myxperiences_org_zone" {
  name = "myxperiences.org"
}

# -------------------------
# SES DOMAIN
# -------------------------

resource "aws_ses_domain_identity" "domain" {
  domain = "myxperiences.org"
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = "${aws_ses_domain_identity.domain.domain}."
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.domain.verification_token]
}

resource "aws_ses_domain_dkim" "domain_dkim" {
  domain = aws_ses_domain_identity.domain.domain
}

resource "aws_route53_record" "dkim_record" {
  count   = length(aws_ses_domain_dkim.domain_dkim.dkim_tokens)
  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = "${aws_ses_domain_dkim.domain_dkim.dkim_tokens[count.index]}._domainkey.myxperiences.org"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.domain_dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_mail_from" "mail_from" {
  domain                 = aws_ses_domain_identity.domain.domain
  mail_from_domain       = "mail.myxperiences.org"
  behavior_on_mx_failure = "UseDefaultValue"
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = "mail.myxperiences.org"
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.us-east-1.amazonses.com"]
}

resource "aws_route53_record" "mail_from_txt" {
  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = "mail.myxperiences.org"
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = "_dmarc.myxperiences.org"
  type    = "TXT"
  ttl     = 300
  records = [
    "v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@myxperiences.org; ruf=mailto:dmarc-failures@myxperiences.org; fo=1"
  ]
}

# -------------------------
# SES SMTP USER
# -------------------------

resource "aws_iam_user" "ses_smtp_user" {
  name = "xperiences-ses-smtp"
}

resource "aws_iam_user_policy_attachment" "ses_smtp_user_policy" {
  user       = aws_iam_user.ses_smtp_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_access_key" "ses_smtp_access_key" {
  user = aws_iam_user.ses_smtp_user.name
}

output "ses_smtp_user_smtp_username" {
  value = aws_iam_access_key.ses_smtp_access_key.id
}

output "ses_smtp_user_smtp_secret_key" {
  value     = aws_iam_access_key.ses_smtp_access_key.secret
  sensitive = true
}

output "ses_smtp_user_smtp_password" {
  value     = aws_iam_access_key.ses_smtp_access_key.ses_smtp_password_v4
  sensitive = true
}

# -------------------------
# ACM CERTIFICATE
# -------------------------

resource "aws_acm_certificate" "xperiences_cert" {
  domain_name       = "myxperiences.org"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.myxperiences.org"
  ]

  tags = {
    Name = "xperiences-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.xperiences_cert.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.myxperiences_org_zone.id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "xperiences_cert_validation" {
  certificate_arn         = aws_acm_certificate.xperiences_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
