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
        source = "https://storage.googleapis.com/circonus-hashistack.appspot.com/fabio/1.2.1/fabio"
        options {
          checksum = "sha256:c716dfba9bc6ab936bccc4653ce39301e276251e01a849decf7f06d8bba582e0"
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
