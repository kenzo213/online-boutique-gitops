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
  set {
    name  = "components.cni.enabled"
    value = "true"
  }
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_cni" {
  name       = "istio-cni"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "cni"
  version    = "1.20.0"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  set {
    name  = "cni.cniBinDir"
    value = "/opt/cni/bin"
  }
  set {
    name  = "cni.cniConfDir"
    value = "/etc/cni/net.d"
  }
  depends_on = [helm_release.istiod]
}
