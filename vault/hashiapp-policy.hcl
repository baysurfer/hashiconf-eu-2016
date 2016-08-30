path "secret/circhashi" {
  capabilities = ["read", "list"]
}

path "mysql/creds/circhashi" {
  capabilities = ["read", "list"]
}

path "sys/renew/*" {
  capabilities = ["update"]
}
