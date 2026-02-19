resource "kubernetes_namespace" "gatekeeper" {
  metadata {
    name = var.gatekeeper_namespace
  }
}

resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = "3.14.0"
  namespace  = kubernetes_namespace.gatekeeper.metadata[0].name

  set {
    name  = "auditInterval"
    value = "30"
  }

  set {
    name  = "violationLimit"
    value = "20"
  }

  depends_on = [kubernetes_namespace.gatekeeper]
}
