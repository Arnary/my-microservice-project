# Загальна інформація
output "namespace" {
  description = "Namespace моніторингу"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "helm_release_name" {
  description = "Назва Helm release"
  value       = helm_release.prometheus_stack.name
}

output "helm_release_status" {
  description = "Статус Helm release"
  value       = helm_release.prometheus_stack.status
}

# Prometheus
output "prometheus_service_name" {
  description = "Назва сервісу Prometheus"
  value       = "${helm_release.prometheus_stack.name}-kube-prom-prometheus"
}

output "prometheus_port" {
  description = "Порт сервісу Prometheus"
  value       = 9090
}

output "prometheus_url" {
  description = "URL для доступу до Prometheus (через port-forward)"
  value       = "http://localhost:9090"
}

# Grafana
output "grafana_service_name" {
  description = "Назва сервісу Grafana"
  value       = "${helm_release.prometheus_stack.name}-grafana"
}

output "grafana_port" {
  description = "Порт сервісу Grafana"
  value       = 80
}

output "grafana_url" {
  description = "URL для доступу до Grafana (через port-forward)"
  value       = "http://localhost:3000"
}

output "grafana_admin_user" {
  description = "Користувач адміністратора Grafana"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  value       = var.grafana_admin_password
  sensitive   = true
}

# Alertmanager
output "alertmanager_service_name" {
  description = "Назва сервісу Alertmanager"
  value       = var.enable_alertmanager ? "${helm_release.prometheus_stack.name}-kube-prom-alertmanager" : null
}

output "alertmanager_port" {
  description = "Порт сервісу Alertmanager"
  value       = var.enable_alertmanager ? 9093 : null
}

output "alertmanager_url" {
  description = "URL для доступу до Alertmanager (через port-forward)"
  value       = var.enable_alertmanager ? "http://localhost:9093" : null
}

# Команди для port-forward
output "port_forward_commands" {
  description = "Команди для port-forward доступу до сервісів"
  value = {
    prometheus = "kubectl port-forward svc/${helm_release.prometheus_stack.name}-kube-prom-prometheus 9090:9090 -n ${var.namespace}"
    grafana    = "kubectl port-forward svc/${helm_release.prometheus_stack.name}-grafana 3000:80 -n ${var.namespace}"
    alertmanager = var.enable_alertmanager ? "kubectl port-forward svc/${helm_release.prometheus_stack.name}-kube-prom-alertmanager 9093:9093 -n ${var.namespace}" : null
  }
}

# Ingress URLs (якщо включено)
output "ingress_urls" {
  description = "URLs для доступу через Ingress"
  value = var.create_ingress ? {
    prometheus   = "https://${var.prometheus_hostname}"
    grafana      = "https://${var.grafana_hostname}"
    alertmanager = var.enable_alertmanager ? "https://${var.alertmanager_hostname}" : null
  } : null
}

# ServiceMonitor інформація
output "service_monitor_name" {
  description = "Назва ServiceMonitor для Django додатка"
  value       = "${var.project_name}-django-metrics"
}

# Конфігурація для інтеграції
output "prometheus_config" {
  description = "Конфігурація для інтеграції з іншими сервісами"
  value = {
    namespace        = var.namespace
    prometheus_url   = "http://${helm_release.prometheus_stack.name}-kube-prom-prometheus.${var.namespace}.svc.cluster.local:9090"
    grafana_url      = "http://${helm_release.prometheus_stack.name}-grafana.${var.namespace}.svc.cluster.local"
    alertmanager_url = var.enable_alertmanager ? "http://${helm_release.prometheus_stack.name}-kube-prom-alertmanager.${var.namespace}.svc.cluster.local:9093" : null
  }
}

# Статус компонентів
output "components_status" {
  description = "Статус компонентів моніторингу"
  value = {
    prometheus        = "Enabled"
    grafana          = "Enabled"
    alertmanager     = var.enable_alertmanager ? "Enabled" : "Disabled"
    node_exporter    = var.enable_node_exporter ? "Enabled" : "Disabled"
    kube_state_metrics = var.enable_kube_state_metrics ? "Enabled" : "Disabled"
  }
}

# Дашборди
output "grafana_dashboards" {
  description = "Список встановлених Grafana дашбордів"
  value = [
    "Kubernetes Cluster Monitoring (ID: 7249)",
    "Kubernetes Pod Monitoring (ID: 6417)", 
    "Node Exporter (ID: 1860)",
    "Kubernetes Deployment (ID: 8588)"
  ]
}

# Метрики endpoints
output "metrics_endpoints" {
  description = "Endpoints для метрик різних сервісів"
  value = {
    prometheus_metrics = "http://${helm_release.prometheus_stack.name}-kube-prom-prometheus.${var.namespace}.svc.cluster.local:9090/metrics"
    grafana_metrics    = "http://${helm_release.prometheus_stack.name}-grafana.${var.namespace}.svc.cluster.local/metrics"
    node_metrics       = var.enable_node_exporter ? "http://node-exporter.${var.namespace}.svc.cluster.local:9100/metrics" : null
    kube_metrics       = var.enable_kube_state_metrics ? "http://kube-state-metrics.${var.namespace}.svc.cluster.local:8080/metrics" : null
  }
}