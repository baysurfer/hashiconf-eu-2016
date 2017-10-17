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
        args = ["agent", "-data-dir", "/var/lib/consul", "-config-file", "/etc/consul/consul.json"]
      }

      artifact {
        source = "https://releases.hashicorp.com/consul/1.0.0/consul_1.0.0_linux_amd64.zip"
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
