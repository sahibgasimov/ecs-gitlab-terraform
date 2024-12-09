# resource "aws_ecr_repository" "app_repository" {
#   name = "${var.app_name}-repository" 

#   tags = {
#     Project = var.app_name
#   }
# }

# resource "aws_ecr_lifecycle_policy" "app_repository_policy" {
#   repository = aws_ecr_repository.app_repository.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Expire untagged images"
#         selection = {
#           tagStatus   = "untagged"
#           countType   = "imageCountMoreThan"
#           countNumber = 10
#         }
#         action = {
#           type = "expire"
#         }
#       },
#       {
#         rulePriority = 2
#         description  = "Retain only the last 5 dev images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["dev"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 5
#         }
#         action = {
#           type = "expire"
#         }
#       },
#       {
#         rulePriority = 3
#         description  = "Retain only the last 5 prod images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["prod"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 5
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }
