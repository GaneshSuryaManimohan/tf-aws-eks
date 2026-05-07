module "vpc" {
  source                = "git::https://github.com/GaneshSuryaManimohan/tf-aws-vpc.git?ref=main"
  project_name          = var.project_name
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  is_peering_required   = var.is_peering_required
  common_tags           = var.common_tags
  public_subnet_tags = {
    "kubernetes.io/cluster/expense" = "shared"
    "kubernetes.io/role/elb"        = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/expense"   = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}