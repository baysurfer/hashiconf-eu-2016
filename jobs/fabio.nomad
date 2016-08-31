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
          checksum = "sha256:4f8bb75cde09eddd35db9a6ee0c699f8a1caecdeab6f6b6e96b82886c2d46047"
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
