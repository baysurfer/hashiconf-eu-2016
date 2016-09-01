# HashiConf NAPA 2016 Demo based on kelseyhightower's awesome [Hashconf EU 2016 presentation] (https://github.com/kelseyhightower/hashiconf-eu-2016).
Well, more than based on, a minor update to include telemetry data for each of the components (Consul, Nomad, Vault, as well as Fabio). Completely awesome example showing the power of Hashicorp's products, with a little bit of Circonus magic thrown in.

## Prerequisites

[Bootstrap the HashiStack on Google Compute Engine](hashistack.md)
[Once this is done you'll see your metrics flowing into your Circonus account.]

Login into the controller node and checkout this repository.

```
gcloud compute ssh ns-1
```

```
git clone https://github.com/vynjo/hashiconf-napa-2016
```

```
cd hashiconf-napa-2016
```

### Create the Hashiapp Policy and Token

```
export VAULT_ADDR=http://ns-1:8200
```

```
vault policy-write hashiapp vault/hashiapp-policy.hcl
```

```
vault token-create \
  -policy="hashiapp" \
  -display-name="hashiapp"
```

Edit `jobs/hashiapp.nomad` job with TOKEN AND MYSQL address

```
env {
  VAULT_TOKEN = "HASHIAPP_TOKEN" 
  VAULT_ADDR = "http://vault.service.consul:8200"
  HASHIAPP_DB_HOST = "CLOUD_SQL:3306"
}
```

### Create the Hashiapp Secret

```
vault write secret/hashiapp jwtsecret=secret
```

## Service Discovery with Consul
 Edit `jobs/consul.nomad` to include `args = ["agent", "-data-dir", "/var/lib/consul"]` TESTING STILL to include telemetry

```
nomad run jobs/consul.nomad
```

```
nomad status consul
```

```
consul join nc-1 nc-2 nc-3 nc-4 nc-5
```

```
consul members
```

## Load Balancing with Fabio

```
nomad run jobs/fabio.nomad
```

```
nomad status fabio
```

## Hashiapp Job

Submit the hashiapp service job.

```
nomad run jobs/hashiapp.nomad
```

```
nomad status hashiapp
```

#### Viewing Logs

```
nomad fs -job hashiapp alloc/logs/hashiapp.stderr.0
nomad fs -job hashiapp alloc/logs/hashiapp.stdout.0
```

#### Send Traffic

```
curl -H "Host: hashiapp.com" http://<loadbalancer-ip>:9999/version
```

### Scaling Up

Edit `jobs/hashiapp.nomad`

```
count = 5
```

```
nomad run jobs/hashiapp.nomad
```

### Rolling Upgrades

Edit `jobs/hashiapp.nomad`

```
source = "https://storage.googleapis.com/hashistack/hashiapp/v2.0.0/hashiapp"
checksum = "sha256:372ddaeb9ac97a2eecd7dd3307bd32f8b0c188d47239f7ef6790609f9a157ca4"
```

```
nomad run jobs/hashiapp.nomad
```
