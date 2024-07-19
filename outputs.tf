output "ingress_ip" {
  value       = data.kubernetes_service_v1.ingress_gateway.status.0.load_balancer.0.ingress.0.ip
  description = "The IP of the ingress gateway"
}

locals {
  out = data.kubernetes_service_v1.ingress_gateway.status.0.load_balancer.0.ingress.0.hostname
}

output "ingress_hostname" {
  value = <<-EOT
    The hostname of the ingress gateway, may need some time to be available for DNS reasons.
        For accessing frontend, access http://${local.out}.
        For accessing admin panel, access http://${local.out}/admin.
        For using main-api-service directly, access http://${local.out}/api/v1/chat/completions.
    EOT
}
