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
      }

      artifact {
        source = "https://storage.cloud.google.com/circonus-hashistack.appspot.com/fabio"
        options {
          checksum = "sha256:95c215faaf47508d6bb79dcc9a396356a518e4016a333419bc2976ff35427754"
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
