module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 21.0"
  name                                     = "expense"
  kubernetes_version                       = "1.30"
  endpoint_public_access                   = false # Should be false for PROD environments, can be true for DEV environments
  enable_cluster_creator_admin_permissions = true  # This is required to give admin permissions to the user who creates the cluster, so that they can create resources in the cluster. This should be set to false for PROD environments, and the admin permissions should be given to a specific IAM role or user.
  addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni = {
      before_compute = true # install BEFORE nodegroup
    }
  }
  vpc_id                   = local.vpc_id
  subnet_ids               = split(",", local.private_subnet_ids)
  control_plane_subnet_ids = split(",", local.private_subnet_ids)
  node_security_group_id   = local.node_sg_id
  
  security_group_additional_rules = {
    bastion_to_cluster = {
      description              = "Allow bastion to reach EKS API"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = data.aws_security_group.bastion.id
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    # blue = {
    #   instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    #   min_size       = 2
    #   max_size       = 10
    #   desired_size   = 2
    #   capacity_type  = "SPOT"
    #   iam_role_additional_policies = {
    #     AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
    #     ElasticLoadBalancingFullAccess    = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    #   }
    #   # EKS takes AWS Linux 2 as it's OS to the nodes
    #   key_name = data.aws_key_pair.eks.key_name
    # }
    green = {
      instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 2
      capacity_type  = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        ElasticLoadBalancingFullAccess    = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = data.aws_key_pair.eks.key_name
    }
  }

  tags = var.common_tags
}