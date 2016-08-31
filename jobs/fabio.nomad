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
        source = "https://storage.googleapis.com/circonus-hashistack.appspot.com/fabio"
        options {
          checksum = "sha256:b96c6b1ad1df75d9b39897581405494e0c5e417ca9a32fd0f6f4a7fa5eb8fcc3"
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
