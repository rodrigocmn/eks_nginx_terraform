# ALB with Nginx ingress controller variables

variable "nginx_replicas" {
  type = "string"
  default = "2"
  description = "Number of Nginx replicas to run in the cluster."
}

variable "nginx_image" {
  type = "string"
  default = "nginx:1.9.1"
  description = "Defines the specific Nginx docker image to be deployed."
}

variable "cluster_endpoint" {
  type = "string"
  description = ""
}

variable "cluster_name" {
  type = "string"
  description = "AWS EKS cluster name"
}