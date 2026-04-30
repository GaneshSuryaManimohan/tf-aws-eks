module "db" {
  #source = "../../tf-aws-sg-module"
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_name = "db"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for database servers"
}

module "ingress" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for Ingress controller"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "ingress"
}

module "cluster" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for EKS Control plane"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "eks-control-plane"
}

module "node" {
  source         = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for EKS node"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "eks-node"
}

module "bastion" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "bastion"
  environment = var.environment
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for bastion servers"
}

module "vpn" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_description = "SG for VPN Instances"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_name = "vpn"
  inbound_rules = var.vpn_sg_rules
}

######Security Group Rules#######
resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

# EKS cluster can be accessed from bastion host
resource "aws_security_group_rule" "cluster_bastion" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.cluster.sg_id
}

# EKS nodes should accept all traffic from nodes with in VPC CIDR range.
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # All traffic
  cidr_blocks = ["10.0.0.0/16"]
  security_group_id = module.node.sg_id
}

# RDS accepting connections from bastion
resource "aws_security_group_rule" "db_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "TCP" # All traffic
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.db.sg_id
}

# DB should accept connections from EKS nodes
resource "aws_security_group_rule" "db_node" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "TCP" # All traffic
  source_security_group_id = module.node.sg_id
  security_group_id = module.db.sg_id
}

# Ingress ALB accepting traffic on 443
resource "aws_security_group_rule" "ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

# Ingress ALB accepting traffic on 80
resource "aws_security_group_rule" "ingress_public_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

# Ingress ALB accepting traffic on 443 from VPC CIDR range (for internal services)
resource "aws_security_group_rule" "node_ingress" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32768
  protocol          = "TCP" # All traffic
  source_security_group_id = module.ingress.sg_id
  security_group_id = module.node.sg_id
}

# EKS control plane accepting all traffic from nodes
resource "aws_security_group_rule" "cluster_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # All traffic
  source_security_group_id = module.node.sg_id
  security_group_id = module.cluster.sg_id
}

#node SG allows inbound from cluster (kubelet, etc.)
resource "aws_security_group_rule" "node_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.cluster.sg_id   # traffic FROM cluster
  security_group_id        = module.node.sg_id       # allowed INTO nodes
}

#node SG allows inbound from other nodes (pod-to-pod traffic)
resource "aws_security_group_rule" "node_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = module.node.sg_id   # self-referencing
  security_group_id        = module.node.sg_id
}