
# Create the RBAC for ALB Ingress Controller
data "template_file" "rbac_role" {
  template = "${file("${path.module}/templates/rbac-role.yaml")}"
  vars {
    cluster_name = "${var.cluster_name}"
  }

}

resource "local_file" "rbac_role_file" {
  content  = "${data.template_file.rbac_role.rendered}"
  filename = "config_output/rbac-role.yaml"

  provisioner "local-exec" {
    command = "kubectl apply -f config_output/rbac-role.yaml"
  }
}


# Deploy ALB Ingress Controller
data "template_file" "alb_ingress_deployment" {
  template = "${file("${path.module}/templates/alb-ingress-controller.yaml")}"
  vars {
    cluster_name = "${var.cluster_name}"
  }

}

resource "local_file" "alb_ingress_deploymentfile" {
  depends_on = ["local_file.rbac_role_file"]
  content  = "${data.template_file.alb_ingress_deployment.rendered}"
  filename = "config_output/alb-ingress-controller.yaml"

  provisioner "local-exec" {
    command = "kubectl apply -f config_output/alb-ingress-controller.yaml"
  }
}

//resource "kubernetes_service_account" "alb_service_account" {
//  metadata {
//    name = "alb-ingress"
//    namespace = "kube-system"
//
//    labels {
//      app = "alb-ingress-controller"
//    }
//
//  }
//}
//
//resource "kubernetes_cluster_role" "alb_rbac_cluster_role" {
//  depends_on = ["kubernetes_service_account.alb_service_account"]
//  metadata {
//    name = "alb-ingress-controller"
//
//    labels {
//      app = "alb-ingress-controller"
//    }
//  }
//
//  rule {
//    api_groups = ["", "extensions"]
//    resources  = ["configmaps", "endpoints", "events", "ingresses", "ingresses/status", "services"]
//    verbs      = ["create", "get", "list", "update", "watch", "patch"]
//
//  }
//
//  rule {
//    api_groups = ["", "extensions"]
//    resources  = ["nodes", "pods", "secrets", "services", "namespaces"]
//    verbs      = ["get", "list", "watch"]
//
//  }
//}
//
//resource "kubernetes_cluster_role_binding" "alb_rbac_cluster_role_binding" {
//  depends_on = ["kubernetes_cluster_role.alb_rbac_cluster_role"]
//
//  metadata {
//    name = "alb-ingress-controller"
//
//    labels {
//      app = "alb-ingress-controller"
//    }
//  }
//
//  role_ref {
//    api_group = "rbac.authorization.k8s.io"
//    kind      = "ClusterRole"
//    name      = "alb-ingress-controller"
//  }
//
//  subject {
//    api_group = ""
//    kind      = "ServiceAccount"
//    name      = "alb-ingress"
//    namespace = "kube-system"
//  }
//}



//resource "kubernetes_deployment" "alb_ingress_controler_deployment" {
//  depends_on = ["local_file.nginx_ingress_file"]
//  metadata {
//    name = "alb-ingress-controller"
//
//    labels {
//      app = "alb-ingress-controller"
//    }
//
//    namespace = "kube-system"
//  }
//
//  spec {
//    replicas = 1
//
//    selector {
//      match_labels {
//        app = "alb-ingress-controller"
//      }
//    }
//
//    strategy {
//      rolling_update {
//        max_surge       = "1"
//        max_unavailable = "1"
//      }
//
//      type = "RollingUpdate"
//    }
//
//    template {
//      metadata {
//        #creationTimestamp = "null"
//        labels {
//          app = "alb-ingress-controller"
//        }
//      }
//
//      spec {
//        container {
//          args                     = ["--ingress-class=alb", "--cluster-name=${var.cluster_name}"]
//          name                     = "server"
//          image                    = "894847497797.dkr.ecr.us-west-2.amazonaws.com/aws-alb-ingress-controller:v1.0.1" # Repository location of the ALB Ingress Controller.
//          image_pull_policy        = "Always"
//          resources                = {}
//          termination_message_path = "/dev/termination-log"
//        }
//
//        dns_policy                       = "ClusterFirst"
//        restart_policy                   = "Always"
//        security_context                 = {}
//        termination_grace_period_seconds = 30
//        service_account_name             = "alb-ingress"
//      }
//    }
//  }
//}

