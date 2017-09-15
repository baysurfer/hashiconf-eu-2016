job "version" {
  datacenters = ["dc1"]

  group "version" {
    count = 5
    task "server" {
      driver = "exec"

      config {
        command = "/usr/bin/curl"
        args = [
          "-H", "Host: hashiapp.com", "http://35.184.46.77:9999/version",
        ]
      }

      resources {
	cpu = 20
	memory = 10
        network {
          mbits = 10
	  port "http" {}
        }
      }
    }
  }
}
chris@ns-1:~/hashiconf-na
