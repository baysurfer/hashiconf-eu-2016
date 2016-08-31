job "hashiapp" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "hashiapp" {
    count = 3

    task "hashiapp" {
      driver = "exec"
      config {
        command = "hashiapp"
      }

      env {
        VAULT_TOKEN = ""
        VAULT_ADDR = "http://vault.service.consul:8200"
        HASHIAPP_DB_HOST = ""
      }

      artifact {
        source = "https://storage.googleapis.com/hashistack/hashiapp/v2.0.0/hashiapp"
        options {
          checksum = "sha256:372ddaeb9ac97a2eecd7dd3307bd32f8b0c188d47239f7ef6790609f9a157ca4"
        }
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1
          port "http" {}
        }
      }

      service {
        name = "hashiapp"
        tags = ["urlprefix-hashiapp.com/"]
        port = "http"
        check {
          type = "http"
          name = "healthz"
          interval = "15s"
          timeout = "5s"
          path = "/healthz"
        }
      }
    }
  }
}
