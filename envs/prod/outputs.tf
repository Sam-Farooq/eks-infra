output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_name" { value = module.eks.cluster_name }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
output "lakehouse_bucket" { value = module.lakehouse_bucket.bucket }
output "rds_secret_arn" {
  value     = module.rds.secret_arn
  sensitive = true
}
