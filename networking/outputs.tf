output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "IDs of the private subnets"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "IDs of the public subnets"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}
