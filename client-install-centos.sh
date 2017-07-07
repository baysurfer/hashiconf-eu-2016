#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

yum update
yum install -y unzip
yum install -y dnsmasq

wget https://releases.hashicorp.com/nomad/0.5.6/nomad_0.5.6_linux_amd64.zip
unzip nomad_0.5.6_linux_amd64.zip
mv nomad /usr/local/bin/

mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

rm nomad_0.5.6_linux_amd64.zip

cat > client.hcl <<EOF
addresses {
    rpc  = "ADVERTISE_ADDR"
    http = "ADVERTISE_ADDR"
}

advertise {
    http = "ADVERTISE_ADDR:4646"
    rpc  = "ADVERTISE_ADDR:4647"
}

telemetry {
	circonus_api_token = "CIRCONUS_API_TOKEN"
	publish_allocation_metrics = "true"
	publish_node_metrics = "true"
	circonus_check_tags = "source:gcp-cjm, type:client, service:hashistack, service:nomad"
     circonus_submission_interval = "1s"
}

data_dir  = "/var/lib/nomad"
log_level = "DEBUG"

client {
    enabled = true
    servers = [
      "ns-1", "ns-2", "ns-3c"
    ]
    options {
        "driver.raw_exec.enable" = "1"
    }
}
EOF
sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" client.hcl
mv client.hcl /etc/nomad/client.hcl

cat > nomad.service <<'EOF'
#!/bin/bash
# chkconfig: 2345 90 60
# description: Nomad - https://nomadproject.io/docs/

# Source function library.
. /etc/init.d/functions

start() {
    # code to start app comes here
    /usr/local/bin/nomad agent -config /etc/nomad &
}

stop() {
    # code to stop app comes here
    killproc nomad
}

case "$1" in
    start)
       start
       ;;
    stop)
       stop
       ;;
    restart)
       stop
       start
       ;;
    status)
       # code to check status of app comes here
       status nomad
       ;;
    *)
       echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0

EOF
mv nomad.service /etc/init.d/nomad
chmod +x /etc/init.d/nomad
chkconfig --add nomad
service nomad start

## Setup up Consul Config file for telemetry

mkdir -p /etc/consul

cat > /etc/consul/consul.json <<EOF
{
	"telemetry": {
		"circonus_api_token": "CIRCONUS_API_TOKEN",
          "circonus_check_tags": "source:gcp-cjm, type:client, service:hashistack, service:consul",
          "circonus_submission_interval": "1s"
	},

	"retry_join": [ "ns-1", "ns-2", "ns-3" ]
}
EOF

## Setup dnsmasq

mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

chkconfig --add dnsmasq
service dnsmasq start
