# Set outputs

output "kubeconfig" {
  value = "${module.k8s_cluster.kubeconfig}"
}


output "cluster_endpoint" {
  value = "${module.k8s_cluster.cluster_endpoint}"
}

