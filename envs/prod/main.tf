locals {
  name = "sf-prod"
  tags = { Environment = "prod", Owner = "platform" }
}

module "vpc" {
  source = "../../modules/vpc"

  name         = local.name
  region       = var.region
  cluster_name = local.name
  cidr         = "10.0.0.0/16"
  az_count     = 3
  # Prod pays for a NAT per AZ. See the comment in modules/vpc.
  single_nat_gateway = false
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = local.name
  kubernetes_version  = "1.31"
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_access_cidrs = var.admin_cidrs
  log_retention_days  = 90

  node_groups = {
    # General workloads. Spot would halve this and these nodes run the
    # ingress controllers, so they stay on demand.
    general = {
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 3
      min_size       = 3
      max_size       = 9
      labels         = { workload = "general" }
      taints         = []
    }
    # Spark executors. Spot, tainted so nothing schedules here by accident,
    # and the streaming drivers explicitly do not tolerate it.
    spark = {
      instance_types = ["r6i.2xlarge", "r5.2xlarge", "r6a.2xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 2
      min_size       = 0
      max_size       = 20
      labels         = { workload = "spark" }
      taints = [{
        key    = "workload"
        value  = "spark"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  tags = local.tags
}

module "lakehouse_bucket" {
  source = "../../modules/s3"

  name                  = "${local.name}-lakehouse"
  transition_to_ia_days = 90
  transition_prefix     = "bronze/"
  tags                  = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  instance_class        = "db.r6g.large"
  allocated_storage     = 100
  max_allocated_storage = 1000
  multi_az              = true
  backup_retention_days = 30
  deletion_protection   = true

  tags = local.tags
}
