variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "kubernetes-admin@kubernetes"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "istio_namespace" {
  description = "Namespace for Istio"
  type        = string
  default     = "istio-system"
}

variable "falco_namespace" {
  description = "Namespace for Falco"
  type        = string
  default     = "falco"
}

variable "gatekeeper_namespace" {
  description = "Namespace for OPA Gatekeeper"
  type        = string
  default     = "gatekeeper-system"
}
