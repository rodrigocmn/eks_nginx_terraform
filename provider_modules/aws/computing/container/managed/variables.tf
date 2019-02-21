#
# k8s managed cluster variables
#


# cluster variables
variable "cluster_name" {
  type    = "string"
}

# networking variables
variable "virtual_network_id" {
  type = "string"
  description = "Virtual Network identification where the cluster will be deployed."
}

variable "subnets_ids" {
  type = "list"
  description = "List of subnets to deploy cluster resources"
}

# Other

variable "workstations_cidr_list" {
  default = ""
  description = "List of workstations that will have access to k8s cluster. This is optional and is usually used for test purposes."
}