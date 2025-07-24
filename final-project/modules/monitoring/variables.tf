variable "namespace" {
  description = "Kubernetes namespace для моніторингу"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Версія Helm чарту kube-prometheus-stack"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_values_file" {
  description = "Шлях до файлу з кастомними значеннями для Prometheus"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "prometheus_retention" {
  description = "Час зберігання метрик Prometheus"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Розмір сховища для Prometheus"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Розмір сховища для Grafana"
  type        = string
  default     = "5Gi"
}

variable "alertmanager_storage_size" {
  description = "Розмір сховища для Alertmanager"
  type        = string
  default     = "2Gi"
}

variable "enable_node_exporter" {
  description = "Увімкнути Node Exporter для збору метрик вузлів"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Увімкнути Kube State Metrics"
  type        = bool
  default     = true
}

variable "enable_alertmanager" {
  description = "Увімкнути Alertmanager для сповіщень"
  type        = bool
  default     = true
}

variable "slack_webhook_url" {
  description = "Webhook URL для Slack сповіщень"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel" {
  description = "Slack канал для сповіщень"
  type        = string
  default     = "#alerts"
}

variable "environment" {
  description = "Назва середовища"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Назва проекту"
  type        = string
  default     = "djangoapp"
}

variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}

variable "create_ingress" {
  description = "Створити Ingress для Grafana"
  type        = bool
  default     = false
}

variable "grafana_hostname" {
  description = "Hostname для Grafana Ingress"
  type        = string
  default     = "grafana.example.com"
}

variable "prometheus_hostname" {
  description = "Hostname для Prometheus Ingress"
  type        = string
  default     = "prometheus.example.com"
}

variable "alertmanager_hostname" {
  description = "Hostname для Alertmanager Ingress"
  type        = string
  default     = "alertmanager.example.com"
}
