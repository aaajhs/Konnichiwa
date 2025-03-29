resource "aws_ecr_repository" "ecr" {
  name                 = local.ecr_repo_name
  image_tag_mutability = "MUTABLE"
}
