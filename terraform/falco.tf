# Falco is installed as a host systemd service on CentOS Stream 10
# due to GCC incompatibility between Falco container images (Debian-based)
# and the CentOS Stream 10 kernel (built with GCC 14.3.1)
# Installation: sudo systemctl status falco-modern-bpf

resource "kubernetes_namespace" "falco" {
  metadata {
    name = var.falco_namespace
    labels = {
      "app" = "falco"
    }
  }
}
