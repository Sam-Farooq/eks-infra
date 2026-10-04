output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_name" { value = module.eks.cluster_name }
output "lakehouse_bucket" { value = module.lakehouse_bucket.bucket }
