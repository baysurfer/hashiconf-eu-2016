job "circhashi" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "circhashi" {
    count = 3

    task "circhashi" {
      driver = "exec"
      config {
        command = "circhashi"
      }

      env {
        VAULT_TOKEN = ""
        VAULT_ADDR = "http://vault.service.consul:8200"
        circhashi_DB_HOST = ""
      }

      artifact {
        source = "https://storage.googleapis.com/hashistack/circhashi/v1.0.0/circhashi"
        options {
          checksum = "sha256:a58ee8c9eb38f2ce45edfbd71547cc66dcb68464b901fe8c89675ad2e12d2135"
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
        name = "circhashi"
        tags = ["urlprefix-circhashi.com/"]
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
