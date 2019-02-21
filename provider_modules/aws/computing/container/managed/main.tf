#####
# EKS Cluster
#
# This section contains the resources to
# create the EKS Cluster.
####

# Load templates

data "template_file" "cluster-retrieve-data" {
  template = "${file("${path.module}/templates/cluster-aws-data-access-policy.json")}"
}

data "template_file" "worker-retrieve-data" {
  template = "${file("${path.module}/templates/worker-aws-data-access-policy.json")}"
}

data "template_file" "alb-ingress-policy" {
  template = "${file("${path.module}/templates/worker-alb-ingress-policy.json")}"
}

# IAM Role to allow EKS service to manage other AWS services
resource "aws_iam_role" "k8s-cluster-role" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = "${data.template_file.cluster-retrieve-data.rendered}"
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.k8s-cluster-role.name}"
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.k8s-cluster-role.name}"
}

# EC2 Security Group to allow networking traffic with EKS cluster
resource "aws_security_group" "k8s-cluster-sg" {
  name        = "${var.cluster_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.virtual_network_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "k8s-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.k8s-cluster-sg.id}"
  source_security_group_id = "${aws_security_group.k8s-node-sg.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "k8s-cluster-ingress-workstation-https" {
  count             = "${var.workstations_cidr_list != "" ? 1 : 0}"
  cidr_blocks       = ["${var.workstations_cidr_list}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.k8s-cluster-sg.id}"
  to_port           = 443
  type              = "ingress"
}

# Create EKS Cluster
resource "aws_eks_cluster" "k8s-cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.k8s-cluster-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.k8s-cluster-sg.id}"]
    subnet_ids         = ["${var.subnets_ids}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.k8s-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.k8s-cluster-AmazonEKSServicePolicy",
  ]
}

####
# EKS Worker Nodes
#
####

# Security role allowing Kubernetes actions to access other services
resource "aws_iam_role" "worker-node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = "${data.template_file.worker-retrieve-data.rendered}"
}

resource "aws_iam_role_policy_attachment" "k8s-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.worker-node.name}"
}

resource "aws_iam_role_policy_attachment" "k8s-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.worker-node.name}"
}

resource "aws_iam_role_policy_attachment" "k8s-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.worker-node.name}"
}

# IAM policy to allow k8s to create AWS ALB

resource "aws_iam_role_policy" "CustomAlbIngress" {
  name   = "CustomAlbIngress"
  policy = "${data.template_file.alb-ingress-policy.rendered}"
  role   = "${aws_iam_role.worker-node.name}"
}

resource "aws_iam_instance_profile" "worker-node" {
  name = "${var.cluster_name}"
  role = "${aws_iam_role.worker-node.name}"
}

# Security Group to allow networking traffic

resource "aws_security_group" "k8s-node-sg" {
  name        = "${var.cluster_name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.virtual_network_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.cluster_name}-node",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "k8s-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.k8s-node-sg.id}"
  source_security_group_id = "${aws_security_group.k8s-node-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "k8s-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.k8s-node-sg.id}"
  source_security_group_id = "${aws_security_group.k8s-cluster-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Data source to fetch latest EKS worker AMI
data "aws_ami" "k8s-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.k8s-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  worker-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.k8s-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.k8s-cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

# Write k8s cluster config files locally

data "template_file" "template_kubeconfig" {
  template = "${file("${path.module}/templates/output-kubeconfig.yaml")}"
  vars {
    cluster_endpoint = "${aws_eks_cluster.k8s-cluster.endpoint}"
    cluster_cert = "${aws_eks_cluster.k8s-cluster.certificate_authority.0.data}"
    cluster_name = "${aws_eks_cluster.k8s-cluster.name}"
  }
}

resource "local_file" "kubeconfig_file" {
  content = "${data.template_file.template_kubeconfig.rendered}"
  filename = "${pathexpand("~/.kube/config")}"
  provisioner "local-exec" {
    command = "chmod 644 ${pathexpand("~/.kube/config")}"
  }
}

# AutoScaling Launch Configuration to configure worker instances
resource "aws_launch_configuration" "k8s-workers-config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.worker-node.name}"
  image_id                    = "${data.aws_ami.k8s-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "${var.cluster_name}"
  security_groups             = ["${aws_security_group.k8s-node-sg.id}"]
  user_data_base64            = "${base64encode(local.worker-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

# AutoScaling Group to launch worker instances
resource "aws_autoscaling_group" "k8s-workers-autoscaling" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.k8s-workers-config.id}"
  max_size             = 2
  min_size             = 1
  name                 = "${var.cluster_name}"
  vpc_zone_identifier  = ["${var.subnets_ids}"]

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

# Join worker nodes to cluster

data "aws_eks_cluster_auth" "k8s_cluster_auth" {
  name = "${var.cluster_name}"
}

provider "kubernetes" {
  host                   = "${aws_eks_cluster.k8s-cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.k8s-cluster.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.k8s_cluster_auth.token}"
  load_config_file       = false
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.worker-node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML
  }
}

# Deploy Ingress Controller
# TODO - Make it flexible to deploy different ingress solutions

module "k8s_ingress_controller" {
  source = "../../../../kubernetes/ingress_controller/alb_nginx_ingress"

  cluster_endpoint = "${aws_eks_cluster.k8s-cluster.endpoint}"
  cluster_name     = "${aws_eks_cluster.k8s-cluster.name}"
}
