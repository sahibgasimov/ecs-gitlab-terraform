resource "aws_acm_certificate" "app_certificate" {
  domain_name       = var.alb_hostname_prod # Use prod domain for ACM validation
  validation_method = "DNS"

  subject_alternative_names = [
    var.alb_hostname_dev # Add dev domain as SAN
  ]

  tags = {
    Environment = var.env_name_prod
    Project     = var.app_name
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_certificate.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "app_certificate_validation" {
  certificate_arn         = aws_acm_certificate.app_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}