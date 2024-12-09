output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the ALB"
}

output "acm_certificate_arn" {
  value       = aws_acm_certificate_validation.app_certificate_validation.certificate_arn
  description = "The ARN of the validated ACM certificate"
}

output "dev_target_group_arn" {
  value       = aws_lb_target_group.dev_target_group.arn
  description = "The ARN of the dev target group"
}

output "prod_target_group_arn" {
  value       = aws_lb_target_group.prod_target_group.arn
  description = "The ARN of the prod target group"
}


# output "ecr_repository_url" {
#   value       = aws_ecr_repository.app_repository.repository_url
#   description = "The URL of the ECR repository"
# }

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS Task Role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "dev_route53_record" {
  value       = aws_route53_record.dev_record.fqdn
  description = "The FQDN of the dev Route 53 record"
}

output "prod_route53_record" {
  value       = aws_route53_record.prod_record.fqdn
  description = "The FQDN of the prod Route 53 record"
}

