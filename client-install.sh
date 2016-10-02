#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
apt-get install -y unzip dnsmasq

wget http://www.vynjo.com/files/nomad/nomad-0.4.1-plus.zip
unzip nomad.zip
mv nomad /usr/local/bin/

mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

rm nomad.zip

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
}

data_dir  = "/var/lib/nomad"
log_level = "DEBUG"

client {
    enabled = true
    servers = [
      "ns-1", "ns-2", "ns-3"
    ]
    options {
        "driver.raw_exec.enable" = "1"
    }
}
EOF
sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" client.hcl
mv client.hcl /etc/nomad/client.hcl

cat > nomad.service <<'EOF'
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/

[Service]
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
mv nomad.service /etc/systemd/system/nomad.service

systemctl enable nomad
systemctl start nomad


## Setup up Consul Config file for telemetry

mkdir -p /etc/consul

cat > /etc/consul/consul.json <<EOF
{
	"telemetry": {
		"circonus_api_token": "CIRCONUS_API_TOKEN"
	}
}
EOF

## Setup dnsmasq

mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

systemctl enable dnsmasq
systemctl start dnsmasq

