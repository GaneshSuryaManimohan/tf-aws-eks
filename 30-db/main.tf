module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.project_name}-${var.environment}-db"

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name                = "transactions" #default database name
  username               = "root"
  port                   = "3306"
  vpc_security_group_ids = [data.aws_ssm_parameter.db_sg_id.value]

  manage_master_user_password = false
  password_wo                 = "ExpenseApp1"
  password_wo_version         = 1
  skip_final_snapshot         = true

  # DB subnet group
  db_subnet_group_name = data.aws_ssm_parameter.db_subnet_group_name.value

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db"
    }
  )

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

# Create R53 record for RDS endpoint
module "zone" {
  source      = "terraform-aws-modules/route53/aws"
  create_zone = false # since zone already exists
  records = {
    db = {
      zone_id = data.aws_route53_zone.existing.zone_id
      name    = "db-${var.environment}"
      type    = "CNAME"
      ttl     = 1
      records = [module.db.db_instance_address]
    }
  }
}