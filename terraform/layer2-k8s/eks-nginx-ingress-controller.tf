locals {
  ssl_certificate_arn = var.nginx_ingress_ssl_terminator == "lb" ? data.terraform_remote_state.layer1-aws.outputs.ssl_certificate_arn : ""

  template_name       = (
    var.nginx_ingress_ssl_terminator == "lb" ? "nginx-ingress-values.yaml" : (
    var.nginx_ingress_ssl_terminator == "nginx" ? "nginx-ingress-certmanager-ssl-termination-values.yaml" : "")
  )
}

data "template_file" "nginx_ingress" {
  template = "${file("${path.module}/templates/${local.template_name}")}"

  vars = {
    hostname           = "${local.domain_name}"
    ssl_cert           = local.ssl_certificate_arn
    proxy_real_ip_cidr = local.vpc_cidr
    namespace          = kubernetes_namespace.ing.id
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  chart      = "nginx-ingress"
  repository = local.helm_repo_stable
  namespace  = kubernetes_namespace.ing.id
  version    = var.nginx_ingress_controller_version
  wait       = false

  values = [
    "${data.template_file.nginx_ingress.rendered}",
  ]
}
