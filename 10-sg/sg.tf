module "db" {
  #source = "../../tf-aws-sg-module"
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "db"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_description = "Security group for database servers"
}

module "ingress" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for Ingress controller"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_name        = "ingress"
}

module "cluster" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for EKS Control plane"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_name        = "eks-control-plane"
}

module "node" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for EKS node"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_name        = "eks-node"
}

module "bastion" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  sg_name        = "bastion"
  environment    = var.environment
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_description = "Security group for bastion servers"
}

module "vpn" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for VPN Instances"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
  sg_name        = "vpn"
  inbound_rules  = var.vpn_sg_rules
}

######Security Group Rules#######

#EKS Cluster accepting traffic from bastion host
resource "aws_security_group_rule" "bastion_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id        = module.cluster.sg_id
}

#Bastion accepting traffic from public
resource "aws_security_group_rule" "public_to_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = module.bastion.sg_id
}

#EKS Nodes accepting traffic from EKS control plane
resource "aws_security_group_rule" "node_to_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1" #ALL Traffic
  source_security_group_id = module.node.sg_id
  security_group_id        = module.cluster.sg_id
}

#EKS control plane accepting traffic from EKS Nodes
resource "aws_security_group_rule" "cluster_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.cluster.sg_id
  security_group_id        = module.node.sg_id
}

#EKS nodes accepting traffic from other nodes within the VPC CIDR range (node to node communication)
resource "aws_security_group_rule" "node_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  cidr_blocks              = ["10.0.0.0/16"]
  security_group_id        = module.node.sg_id
}

#DB accepting traffic from Bastion host
resource "aws_security_group_rule" "bastion_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id        = module.db.sg_id
}

# DB accepting traffic from EKS nodes (if applications running in EKS need to access DB)
resource "aws_security_group_rule" "node_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.node.sg_id
  security_group_id        = module.db.sg_id
}

#Ingress accepting traffic from public (for applications exposed via ALB) HTTPS
resource "aws_security_group_rule" "public_to_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = module.ingress.sg_id
}

#Ingress accepting traffic from public (for applications exposed via ALB) HTTP
resource "aws_security_group_rule" "public_to_ingress_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = module.ingress.sg_id
}

#Ingress accepting traffic from EKS nodes (for applications exposed via NodePort or ClusterIP services)
resource "aws_security_group_rule" "node_to_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.ingress.sg_id
  security_group_id        = data.aws_ssm_parameter.eks_node_sg_id.value
}


resource "aws_security_group_rule" "eks_managed_node_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = data.aws_ssm_parameter.eks_node_sg_id.value
  security_group_id        = module.db.sg_id
}