#
# Outputs
#

output "kubeconfig" {
  value = "${data.template_file.template_kubeconfig.rendered}"
}

output "cluster_endpoint" {
  value = "${aws_eks_cluster.k8s-cluster.endpoint}"
}