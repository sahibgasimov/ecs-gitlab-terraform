variable "route53_zone_id" {
  type        = string
  description = "The ID of the Route53 hosted zone used for ACM validation"
}

variable "region" {
  type        = string
  description = "Region to deploy resources"
}

variable "env_name_dev" {
  type        = string
  description = "Name of the environment to deploy"
}

variable "env_name_prod" {
  type        = string
  description = "Name of the environment to deploy"
}

variable "account_id" {
  type        = string
  description = "Account ID for target account"
}

variable "alb_hostname_dev" {
  type        = string
  description = "Hostname for the dev environment"
}

variable "alb_hostname_prod" {
  type        = string
  description = "Hostname for the prod environment"
}

variable "app_name" {
  type        = string
  description = "Application name"
  default     = "web-app"
}
