module "db_sg" {
  #source = "../../tf-aws-sg-module"
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_name = "db"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for database servers"
}

module "backend_sg" {
  #source = "../../tf-aws-sg-module"
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_name = "backend"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for backend servers"
}

module "frontend_sg" {
  #source = "../../tf-aws-sg-module"
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "frontend"
  environment = var.environment
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for frontend servers"
}

module "bastion_sg" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "bastion"
  environment = var.environment
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for bastion servers"
}

module "alb_sg" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "app-alb"
  environment = var.environment
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for App ALB"
}

module "vpn_sg" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "vpn"
  environment = var.environment
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
  sg_description = "Security group for VPN"
  inbound_rules = var.vpn_sg_rules
}

module "web_alb" {
  source = "git::https://github.com/GaneshSuryaManimohan/tf-aws-sg-module.git?ref=main"
  project_name = var.project_name
  sg_name = "web-alb"
  environment = var.environment
  sg_description = "SG for Web ALB Instances"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = var.common_tags
}

#### Security Group Rules ####
resource "aws_security_group_rule" "db_inbound_from_backend" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.backend_sg.sg_id #source is backend SG
  security_group_id        = module.db_sg.sg_id #target is db SG
  description              = "Allow MySQL access from backend SG"

}

resource "aws_security_group_rule" "db_inbound_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id #source is bastion SG
  security_group_id        = module.db_sg.sg_id #target is db SG
  description              = "Allow SSH access from bastion SG"
  
}

resource "aws_security_group_rule" "db_inbound_from_vpn" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.vpn_sg.sg_id #source is VPN SG
  security_group_id        = module.db_sg.sg_id #target is db SG
  description              = "Allow DB access from VPN SG"   
}

resource "aws_security_group_rule" "backend_inbound_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.alb_sg.sg_id #source is ALB SG
  security_group_id        = module.backend_sg.sg_id #target is backend SG
  description              = "Allow backend access from ALB SG"
}

resource "aws_security_group_rule" "backend_inbound_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id #source is bastion SG
  security_group_id        = module.backend_sg.sg_id #target is backend SG
  description              = "Allow SSH access from bastion SG"
  
}

resource "aws_security_group_rule" "backend_inbound_from_vpn_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.vpn_sg.sg_id #source is VPN SG
  security_group_id        = module.backend_sg.sg_id #target is backend SG
  description              = "Allow backend access from VPN SG"  
}

resource "aws_security_group_rule" "backend_inbound_from_vpn_http" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.vpn_sg.sg_id #source is VPN SG
  security_group_id        = module.backend_sg.sg_id #target is backend SG
  description              = "Allow backend access from VPN SG"    
}

resource "aws_security_group_rule" "frontend_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = module.frontend_sg.sg_id #target is frontend SG
  cidr_blocks       = ["0.0.0.0/0"] #source is anywhere
  description       = "Allow HTTP access from anywhere"
}

resource "aws_security_group_rule" "frontend_inbound_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.frontend_sg.sg_id #target is frontend SG
  source_security_group_id = module.bastion_sg.sg_id #source is bastion SG
  description              = "Allow SSH access from bastion SG"
}

resource "aws_security_group_rule" "frontend_inbound_from_public" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"] #source is public
  security_group_id        = module.frontend_sg.sg_id #target is frontend SG
  description              = "Allow SSH access from public to frontend"
}

resource "aws_security_group_rule" "bastion_inbound_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.bastion_sg.sg_id #target is bastion SG
  cidr_blocks       = ["0.0.0.0/0"] #source is anywhere
  description       = "Allow SSH access from anywhere"
}

resource "aws_security_group_rule" "app_alb_inbound_from_vpn" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.vpn_sg.sg_id #source is VPN SG
  security_group_id        = module.alb_sg.sg_id #target is ALB SG
  description              = "Allow ALB access from VPN SG"  
}

resource "aws_security_group_rule" "app_alb_inbound_from_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.frontend_sg.sg_id #source is VPN SG
  security_group_id        = module.alb_sg.sg_id #target is ALB SG
  description              = "Allow ALB access from VPN SG"  
}

resource "aws_security_group_rule" "web_alb_public" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.web_alb.sg_id
}

resource "aws_security_group_rule" "web_alb_public_https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.web_alb.sg_id
}

# Added as a part of Jenkins CICD
resource "aws_security_group_rule" "backend_inbound_from_default_VPC" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["172.31.0.0/16"]
  security_group_id = module.backend_sg.sg_id
}

# Added as a part of Jenkins CICD
resource "aws_security_group_rule" "frontend_inbound_from_default_VPC" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["172.31.0.0/16"]
  security_group_id = module.frontend_sg.sg_id
}