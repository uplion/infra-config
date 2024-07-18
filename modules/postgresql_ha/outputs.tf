output "postgres_password" {
  value     = random_password.postgresql.result
  sensitive = true
}
