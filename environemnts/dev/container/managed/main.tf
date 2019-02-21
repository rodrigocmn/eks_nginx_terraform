#
# Provider Configuration
#

provider "aws" {
  region = "us-west-2"
}

provider "template" {}

#
# Retrive the workstation IP address for the cluster security rules
#
provider "http" {}

data "http" "workstation_external_ip" {
  url = "http://ipv4.icanhazip.com"
}

# Override with variable or hardcoded value if necessary
locals {
  workstation_external_cidr = "${chomp(data.http.workstation_external_ip.body)}/32"
  cluster_name = "rods-eks"
}

# Network configuration
module "vpc" {
  source = "../../../../provider_modules/aws/networking/vitual_network"

  # The following tags are required for EKS to discover and manage AWS resources.
  vpc_tags = "${
    map(
      "Name", "${local.cluster_name}-node",
      "kubernetes.io/cluster/${local.cluster_name}", "shared",
    )
  }"
  igw_tags = "${
    map(
      "Name", "${local.cluster_name}",
    )
  }"
  subnet_tags = "${
    map(
      "Name", "${local.cluster_name}-node",
      "kubernetes.io/cluster/${local.cluster_name}", "shared",
      "kubernetes.io/role/elb", "",
      "kubernetes.io/role/internal-elb", "",
    )
  }"

}

# K8s cluster configuration
module "k8s_cluster" {
  source = "../../../../provider_modules/aws/computing/container/managed"

  cluster_name        = "${local.cluster_name}"
  virtual_network_id  = "${module.vpc.virtual_network_id}"
  subnets_ids         = "${module.vpc.subnets_ids}"
  workstations_cidr_list = "${local.workstation_external_cidr}"
}
