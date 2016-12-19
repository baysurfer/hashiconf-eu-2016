#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

apt-get update
apt-get install -y unzip dnsmasq

wget https://releases.hashicorp.com/nomad/0.5.1/nomad_0.5.1_linux_amd64.zip
unzip nomad_0.5.1_linux_amd64.zip
chmod +x nomad
mv nomad /usr/local/bin/nomad


mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

rm nomad_0.5.1_linux_amd64.zip

cat > server.hcl <<EOF
addresses {
    rpc  = "ADVERTISE_ADDR"
    serf = "ADVERTISE_ADDR"
}

advertise {
    http = "ADVERTISE_ADDR:4646"
    rpc  = "ADVERTISE_ADDR:4647"
    serf = "ADVERTISE_ADDR:4648"
}

bind_addr = "0.0.0.0"
data_dir  = "/var/lib/nomad"
log_level = "DEBUG"

server {
    enabled = true
    bootstrap_expect = 3
}

telemetry {
	circonus_api_token = "CIRCONUS-API-TOKEN"
	circonus_check_tags = "type:server, service:hashistack, service:nomad"
}

EOF
sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" server.hcl
mv server.hcl /etc/nomad/server.hcl

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

## Setup consul

mkdir -p /var/lib/consul

wget https://releases.hashicorp.com/consul/0.7.2-rc1/consul_0.7.2-rc1_linux_amd64.zip
unzip consul_0.7.2-rc1_linux_amd64.zip
mv consul /usr/local/bin/consul
rm consul_0.7.2-rc1_linux_amd64.zip

mkdir -p /etc/consul

cat > /etc/consul/consul.json <<'EOF'
{
	"telemetry": {
		"circonus_api_token": "CIRCONUS-API-TOKEN"
		"circonus_check_tags": "type:server, service:consul, service:hashistack"
	}
}
EOF

cat > consul.service <<'EOF'
[Unit]
Description=consul
Documentation=https://consul.io/docs/

[Service]
ExecStart=/usr/local/bin/consul agent \
  -advertise=ADVERTISE_ADDR \
  -bind=0.0.0.0 \
  -bootstrap-expect=3 \
  -client=0.0.0.0 \
  -data-dir=/var/lib/consul \
  -server \
  -ui \
  -config-file=/etc/consul/consul.json
  
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" consul.service
mv consul.service /etc/systemd/system/consul.service
systemctl enable consul
systemctl start consul

## Setup Vault

wget https://releases.hashicorp.com/vault/0.6.3/vault_0.6.3_linux_amd64.zip
unzip vault_0.6.3_linux_amd64.zip
mv vault /usr/local/bin/vault
rm vault_0.6.3_linux_amd64.zip

mkdir -p /etc/vault

cat > /etc/vault/vault.hcl <<'EOF'
backend "consul" {
  advertise_addr = "http://ADVERTISE_ADDR:8200"
  address = "127.0.0.1:8500"
  path = "vault"
}

listener "tcp" {
  address = "ADVERTISE_ADDR:8200"
  tls_disable = 1
}

telemetry {
	circonus_api_token = "CIRCONUS-API-TOKEN"
	circonus_check_tags = "type:server, service:hashistack, service:vault"
}

EOF

sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" /etc/vault/vault.hcl

cat > /etc/systemd/system/vault.service <<'EOF'
[Unit]
Description=Vault
Documentation=https://vaultproject.io/docs/

[Service]
ExecStart=/usr/local/bin/vault server \
  -config /etc/vault/vault.hcl
  
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vault
systemctl start vault

## Setup dnsmasq

mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

systemctl enable dnsmasq
systemctl start dnsmasq
