resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }
  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }
  set {
    name  = "grafana.service.type"
    value = "NodePort"
  }
  set {
    name  = "grafana.service.nodePort"
    value = "32000"
  }
  set {
    name  = "prometheus.service.type"
    value = "NodePort"
  }
  set {
    name  = "prometheus.service.nodePort"
    value = "32001"
  }
  set {
    name  = "alertmanager.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.enabled"
    value = "false"
  }
  set {
    name  = "prometheus.enabled"
    value = "false"
  }
  set {
    name  = "loki.persistence.enabled"
    value = "false"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
