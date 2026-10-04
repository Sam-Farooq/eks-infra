locals {
  name = "sf-staging"
  tags = { Environment = "staging", Owner = "platform" }
}

module "vpc" {
  source = "../../modules/vpc"

  name         = local.name
  region       = var.region
  cluster_name = local.name
  cidr         = "10.1.0.0/16"
  az_count     = 2
  # One NAT. About $90/month saved, and nobody is paged if it fails.
  single_nat_gateway = true
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = local.name
  kubernetes_version  = "1.31"
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_access_cidrs = var.admin_cidrs
  log_retention_days  = 14

  node_groups = {
    general = {
      # All spot in staging. A node going away here is a useful rehearsal.
      instance_types = ["m6i.large", "m5.large", "m6a.large"]
      capacity_type  = "SPOT"
      desired_size   = 2
      min_size       = 1
      max_size       = 6
      labels         = { workload = "general" }
      taints         = []
    }
  }

  tags = local.tags
}

module "lakehouse_bucket" {
  source = "../../modules/s3"

  name = "${local.name}-lakehouse"
  # No tiering: staging data is deleted long before 90 days.
  transition_to_ia_days = 0
  tags                  = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  instance_class        = "db.t4g.medium"
  allocated_storage     = 20
  multi_az              = false
  backup_retention_days = 1
  # Off, so a teardown does not need a console visit.
  deletion_protection = false

  tags = local.tags
}
