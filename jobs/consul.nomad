job "consul" {
  datacenters = ["dc1"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "consul-agent" {
    task "consul-agent" {
      driver = "exec"
      config {
        command = "consul"
        args = ["agent", "-data-dir", "/var/lib/consul"] 
      }

      artifact {
        source = "https://releases.hashicorp.com/consul/0.7.0-rc2/consul_0.7.0-rc2_linux_amd64.zip"
        options {
          checksum = "sha256:adcf13cbeaf13f9839e4b0914a04926d49e9bd47df75cdc30117818f69a0ae5b"
        }
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1

          port "server" {
            static = 8300
          }
          port "serf_lan" {
            static = 8301
          }
          port "serf_wan" {
            static = 8302
          }
          port "rpc" {
            static = 8400
          }
          port "http" {
            static = 8500
          }
          port "dns" {
            static = 8600
          }
        }
      }
    }
  }
}
