job "fabio" {
  datacenters = ["dc1"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "fabio" {
    task "fabio" {
      driver = "exec"
      config {
        command = "fabio"
                args = ["-metrics.circonus.apikey", "CIRCONUS_API_TOKEN", "-metrics.target", "circonus", "-metrics.names", "{{.Service}}`{{.Host}}{{.Path}}`latency_ns"]
      }

      artifact {
        source = "http://www.vynjo.com/files/fabio/1.2.1/fabio"
        options {
          checksum = "sha256:b2a36f48abd0cf5226d95bc505799a1513279da7f12a75a5bc406d220ec60c40"
        }
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1

          port "http" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}
