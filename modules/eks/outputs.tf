output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_ca" { value = aws_eks_cluster.this.certificate_authority[0].data }
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.this.arn }
output "oidc_issuer" { value = aws_eks_cluster.this.identity[0].oidc[0].issuer }

# The SG EKS creates for the control plane and managed nodes. The RDS module
# allows ingress from it, which is how the cluster reaches Postgres without a
# hand-maintained CIDR list.
output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" { value = aws_iam_role.node.arn }
