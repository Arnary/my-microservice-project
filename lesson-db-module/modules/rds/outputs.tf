output "endpoint" {
  description = "DNS-адреса для бази даних"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "writer_endpoint" {
  description = "DNS-адреса для запису"
  value       = var.use_aurora ? aws_rds_cluster_instance.writer[0].endpoint : ""
}

output "reader_endpoints" {
  description = "Список DNS-адрес для читання"
  value       = var.use_aurora ? aws_rds_cluster_instance.readers[*].endpoint : []
}
