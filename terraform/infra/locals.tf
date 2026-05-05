/*locals {
  az1 = data.aws_availability_zones.available.names[0]
  az2 = data.aws_availability_zones.available.names[1]
  az3 = data.aws_availability_zones.available.names[2]

  app_image = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

  name = var.project_name
}*/