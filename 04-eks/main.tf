module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 21.0"

    name = "expense"
    kubernetes_version= "1.32"

    endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    vpc_id     = local.vpc_id
    subnet_ids = split(",", local.private_subnet_ids)
    control_plane_subnet_ids = split(",", local.private_subnet_ids)

}





