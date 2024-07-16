output "postgres_dbname" {
  value       = base64decode(jsondecode(data.kubernetes_secret_v1.postgres_ha.data[0])["data"]["dbname"])
  description = "The name of the database to create"
}

output "postgres_username" {
  value       = base64decode(jsondecode(data.kubernetes_secret_v1.postgres_ha.data[0])["data"]["user"])
  description = "The name of the user to create"
}

output "postgres_password" {
  value       = base64decode(jsondecode(data.kubernetes_secret_v1.postgres_ha.data[0])["data"]["password"])
  description = "The password of the user to create"
}

output "postgres_host" {
  value       = base64decode(jsondecode(data.kubernetes_secret_v1.postgres_ha.data[0])["data"]["pgbouncer-host"])
  description = "The host of the Postgres instance"
}

output "postgres_port" {
  value       = base64decode(jsondecode(data.kubernetes_secret_v1.postgres_ha.data[0])["data"]["pgbouncer-port"])
  description = "The port of the Postgres instance"
}
