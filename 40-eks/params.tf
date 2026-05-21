resource "aws_ssm_parameter" "eks_node_sg_id" {
  name  = "/${var.project_name}/${var.environment}/eks_node_sg_id"
  type  = "String"
  value = module.eks.node_security_group_id
}