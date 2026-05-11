output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "app_pod_role_arn" {
  value = aws_iam_role.app_pod.arn
}

output "lbc_role_arn" {
  value = aws_iam_role.lbc.arn
}

output "app_pod_role_name" {
  value = aws_iam_role.app_pod.name
}