# module "ecr" {
#   source = "terraform-aws-modules/ecr/aws"

#   repository_name = "test_bp"

# #   repository_read_write_access_arns = ["arn:aws:iam::012345678901:role/terraform"]
#   repository_lifecycle_policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1,
#         description  = "Keep last 30 images",
#         selection = {
#           tagStatus     = "tagged",
#           tagPrefixList = ["v"],
#           countType     = "imageCountMoreThan",
#           countNumber   = 30
#         },
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#     owner = "binay"
#   }
# }

# resource "aws_ecr_repository" "test_repository" {
#   name = "test_repository" 
#   image_scanning_configuration {
#     scan_on_push = true  # Enable image scanning on push
#   }
# }
