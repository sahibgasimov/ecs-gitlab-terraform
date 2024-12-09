#############ROUTE53##############

resource "aws_route53_record" "dev_record" {
  zone_id = var.route53_zone_id
  name    = var.alb_hostname_dev
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "prod_record" {
  zone_id = var.route53_zone_id
  name    = var.alb_hostname_prod
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}
