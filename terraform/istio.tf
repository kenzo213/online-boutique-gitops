resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = var.istio_namespace
  }
}

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.20.0"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  depends_on = [kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.20.0"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "pilot.traceSampling"
    value = "100"
  }

  depends_on = [helm_release.istio_base]
}
