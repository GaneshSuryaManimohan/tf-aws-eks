locals {
  private_subnet_ids = data.aws_ssm_parameter.private_subnet_ids.value
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}