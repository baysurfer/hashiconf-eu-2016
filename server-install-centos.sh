#!/bin/bash

export IP_ADDRESS=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

yum update
yum install -y unzip
yum install -y dnsmasq

wget https://releases.hashicorp.com/nomad/0.6.3/nomad_0.6.3_linux_amd64.zip
unzip nomad_0.6.3_linux_amd64.zip
chmod +x nomad
mv nomad /usr/local/bin/nomad


mkdir -p /var/lib/nomad
mkdir -p /etc/nomad

rm nomad_0.6.3_linux_amd64.zip

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
	circonus_api_token = "2c1518f9-10ae-49b8-9b04-c386616aae09"
	circonus_check_tags = "source:gcp, type:server, service:hashistack, service:nomad"
     circonus_submission_interval = "1s"
     publish_node_metrics = "true"
}

EOF
sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" server.hcl
mv server.hcl /etc/nomad/server.hcl

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

## Setup consul

mkdir -p /var/lib/consul

wget https://releases.hashicorp.com/consul/0.9.3/consul_0.9.3_linux_amd64.zip
unzip consul_0.9.3_linux_amd64.zip
mv consul /usr/local/bin/consul
rm consul_0.9.3_linux_amd64.zip

mkdir -p /etc/consul

cat > /etc/consul/consul.json <<'EOF'
{
	"telemetry": {
		"circonus_api_token": "CIRCONUS-API-TOKEN",
		"circonus_check_tags": "source:gcp, type:server, service:consul, service:hashistack"
	}
}
EOF

cat > consul.service <<'EOF'
#!/bin/bash
# chkconfig: 2345 90 60
# description: Consul - https://consul.io/docs/
# Source function library.
. /etc/init.d/functions
start() {
    # code to start app comes here
    /usr/local/bin/consul agent \
  -advertise=ADVERTISE_ADDR \
  -bind=0.0.0.0 \
  -bootstrap-expect=3 \
  -client=0.0.0.0 \
  -data-dir=/var/lib/consul \
  -server \
  -ui \
  -config-file=/etc/consul/consul.json &
}
stop() {
    # code to stop app comes here
    killproc consul
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
       status consul
       ;;
    *)
       echo "Usage: $0 {start|stop|status|restart}"
esac
exit 0
EOF

sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" consul.service
mv consul.service /etc/init.d/consul
chmod +x /etc/init.d/consul
chkconfig --add consul
service consul start

## Setup Vault

wget https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip
unzip vault_0.8.3_linux_amd64.zip
mv vault /usr/local/bin/vault
rm vault_0.8.3_linux_amd64.zip

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
	circonus_check_tags = "source:gcp, type:server, service:hashistack, service:vault"
}

EOF

sed -i "s/ADVERTISE_ADDR/${IP_ADDRESS}/" /etc/vault/vault.hcl

cat > vault.service <<'EOF'
#!/bin/bash
# chkconfig: 2345 90 60
# description: Vault - https://vaultproject.io/docs/
# Source function library.
. /etc/init.d/functions
start() {
    # code to start app comes here
    /usr/local/bin/vault server \
  -config /etc/vault/vault.hcl &
}
stop() {
    # code to stop app comes here
    killproc vault
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
       status vault
       ;;
    *)
       echo "Usage: $0 {start|stop|status|restart}"
esac
exit 0
EOF
mv vault.service /etc/init.d/vault
chmod +x /etc/init.d/vault

chkconfig --add vault
service vault start

## Setup dnsmasq

mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/10-consul <<'EOF'
server=/consul/127.0.0.1#8600
EOF

chkconfig --add dnsmasq
service dnsmasq start
