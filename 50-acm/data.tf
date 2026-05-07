data "aws_route53_zone" "existing" {
  name         = var.zone_name
  private_zone = false
}