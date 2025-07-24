resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    
    labels = merge({
      name        = var.namespace
      environment = var.environment
      project     = var.project_name
    }, var.tags)
  }
}

# Helm release для kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Використовуємо кастомний values файл або default
  values = [
    var.prometheus_values_file != "" ? file(var.prometheus_values_file) : templatefile("${path.module}/values.yaml", {
      prometheus_retention      = var.prometheus_retention
      prometheus_storage_size   = var.prometheus_storage_size
      grafana_storage_size      = var.grafana_storage_size
      alertmanager_storage_size = var.alertmanager_storage_size
      grafana_admin_password    = var.grafana_admin_password
      enable_alertmanager       = var.enable_alertmanager
      enable_node_exporter      = var.enable_node_exporter
      enable_kube_state_metrics = var.enable_kube_state_metrics
      slack_webhook_url         = var.slack_webhook_url
      slack_channel             = var.slack_channel
      create_ingress            = var.create_ingress
      grafana_hostname          = var.grafana_hostname
      prometheus_hostname       = var.prometheus_hostname
      alertmanager_hostname     = var.alertmanager_hostname
    })
  ]

  # Встановлення CRDs
  create_namespace = false
  
  # Timeout для встановлення
  timeout = 600

  # Залежності
  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# ServiceMonitor для Django додатка
resource "kubernetes_manifest" "django_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    
    metadata = {
      name      = "${var.project_name}-django-metrics"
      namespace = var.namespace
      labels = {
        app         = "${var.project_name}-django"
        environment = var.environment
      }
    }
    
    spec = {
      selector = {
        matchLabels = {
          app = "${var.project_name}-django"
        }
      }
      
      endpoints = [
        {
          port     = "http"
          path     = "/metrics"
          interval = "30s"
        }
      ]
      
      namespaceSelector = {
        matchNames = ["default"]
      }
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

# ConfigMap з додатковими правилами Prometheus
resource "kubernetes_config_map" "prometheus_rules" {
  metadata {
    name      = "${var.project_name}-prometheus-rules"
    namespace = var.namespace
    
    labels = {
      app         = "prometheus"
      environment = var.environment
      project     = var.project_name
    }
  }

  data = {
    "custom-rules.yaml" = yamlencode({
      groups = [
        {
          name = "${var.project_name}-alerts"
          rules = [
            {
              alert = "HighMemoryUsage"
              expr  = "container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.8"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High memory usage detected"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 80% of its memory limit"
              }
            },
            {
              alert = "HighCPUUsage"
              expr  = "rate(container_cpu_usage_seconds_total[5m]) > 0.8"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CPU usage detected"
                description = "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 80% CPU"
              }
            },
            {
              alert = "PodRestarting"
              expr  = "rate(kube_pod_container_status_restarts_total[15m]) > 0"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Pod is restarting frequently"
                description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has restarted {{ $value }} times in the last 15 minutes"
              }
            }
          ]
        }
      ]
    })
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Secret для AlertManager конфігурації
resource "kubernetes_secret" "alertmanager_config" {
  count = var.enable_alertmanager && var.slack_webhook_url != "" ? 1 : 0

  metadata {
    name      = "alertmanager-${helm_release.prometheus_stack.name}-kube-prom-alertmanager"
    namespace = var.namespace
  }

  data = {
    "alertmanager.yml" = yamlencode({
      global = {
        slack_api_url = var.slack_webhook_url
      }
      
      route = {
        group_by        = ["alertname"]
        group_wait      = "10s"
        group_interval  = "10s"
        repeat_interval = "1h"
        receiver        = "slack-notifications"
      }
      
      receivers = [
        {
          name = "slack-notifications"
          slack_configs = [
            {
              channel   = var.slack_channel
              title     = "[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }}"
              text      = "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}"
              send_resolved = true
            }
          ]
        }
      ]
    })
  }

  depends_on = [helm_release.prometheus_stack]
}

# NetworkPolicy для безпеки
resource "kubernetes_network_policy" "monitoring_network_policy" {
  metadata {
    name      = "${var.project_name}-monitoring-network-policy"
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = "prometheus"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = var.namespace
          }
        }
      }
      
      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }

    egress {
      # Дозволити весь вихідний трафік для scraping метрик
      to {}
      
      ports {
        port     = "443"
        protocol = "TCP"
      }
      
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}