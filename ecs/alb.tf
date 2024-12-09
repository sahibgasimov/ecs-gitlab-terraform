resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg_alb.security_group_id]
  subnets            = local.public_subnets

  enable_deletion_protection = false

  tags = {
    Project = var.app_name
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app_certificate_validation.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
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

resource "aws_lb_listener_rule" "dev_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    host_header {
      values = [var.alb_hostname_dev]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_target_group.arn
  }
}

resource "aws_lb_listener_rule" "prod_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  condition {
    host_header {
      values = [var.alb_hostname_prod]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_target_group.arn
  }
}


resource "aws_lb_target_group" "dev_target_group" {
  name        = "${var.app_name}-dev-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Environment = var.env_name_dev
    Project     = var.app_name
  }
}

resource "aws_lb_target_group" "prod_target_group" {
  name        = "${var.app_name}-prod-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Environment = var.env_name_prod
    Project     = var.app_name
  }
}

