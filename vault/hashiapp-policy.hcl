path "secret/hashiapp" {
  capabilities = ["read", "list"]
}

path "mysql/creds/hashiapp" {
  capabilities = ["read", "list"]
}

path "sys/renew/*" {
  capabilities = ["update"]
}
