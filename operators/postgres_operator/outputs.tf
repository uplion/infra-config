output "postgres_dbname" {
  value       = base64decode(data.kubernetes_secret_v1.postgres_ha.data["dbname"])
  description = "The name of the database to create"
}

output "postgres_username" {
  value       = base64decode(data.kubernetes_secret_v1.postgres_ha.data["user"])
  description = "The name of the user to create"
}

output "postgres_password" {
  value       = base64decode(data.kubernetes_secret_v1.postgres_ha.data["password"])
  description = "The password of the user to create"
}

output "postgres_host" {
  value       = base64decode(data.kubernetes_secret_v1.postgres_ha.data["pgbouncer-host"])
  description = "The host of the Postgres instance"
}

output "postgres_port" {
  value       = base64decode(data.kubernetes_secret_v1.postgres_ha.data["pgbouncer-port"])
  description = "The port of the Postgres instance"
}
