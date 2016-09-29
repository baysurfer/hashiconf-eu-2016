job "hashiapp" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "5s"
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
	  	VAULT_TOKEN = "HASHIAPP_TOKEN" 
	  	VAULT_ADDR = "http://vault.service.consul:8200"
	  	HASHIAPP_DB_HOST = "CLOUD_SQL:3306"
      }

      artifact {
        source = "http://www.vynjo.com/files/hashiapp/v2/hashiapp"
        options {
          checksum = "sha256:258d4f1568a275184c151edabac3fab4f087ffd589a0d42443411818931dde16"
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
