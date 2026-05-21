data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id"
}

# Fetch the EKS-managed node SG
data "aws_ssm_parameter" "eks_node_sg_id" {
  name = "/${var.project_name}/${var.environment}/eks_node_sg_id"
}