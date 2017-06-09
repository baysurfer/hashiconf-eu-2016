# This is basis of the demo that Circonus was using at HashiConf NAPA 2016.

<p>It is based based on kelseyhightower's awesome [Hashconf EU 2016 presentation] (https://github.com/kelseyhightower/hashiconf-eu-2016).
Well, more than based on, a minor update to include telemetry data for each of the components (Consul, Nomad, Vault, as well as Fabio).</p>

<p>Completely awesome example showing the power of Hashicorp's products, with a little bit of Circonus magic thrown in.</p>

<p>So, if you follow the instructions below, you'll end up with a deployment that looks something like this:</p>
![](http://www.vynjo.com/files/hashistack/hashistack_diagram.png)


#Overview
Once you have completed the setup, you will have:
<ul>
<li>a 3 node server cluster (ns-1, ns-2, ns-3) running Consul, Nomad, and Vault servers. Each member of the cluster will AUTOMATICALLY create a corresponding set of Circonus metrics for each of the servers (Consul, Nomad, and Vault). These metrics will include the all important latency metrics (represented via histograms in Circonus), as well as basic information on CPU, Memory, and Disk utilization</li>
<li>5 client machines with Nomad configured in agent mode, and, again, each of these machines will AUTOMATICALLY create a set of Circonus metrics with similar information as that of the Servers. </li>
<li>A MySQL instance (to store the VAULT secrets)</li>
<li>A load balancer (to give you one public IP)</li>
</ul>

Now that you have the basic infrastructure, you'll then launch two nomad jobs
<ul>
<li>Consul in agent mode</li>
<li>Fabio, a sophisticated software load balancer</li>
</ul>

These nomad jobs are configured to run a single allocation on each of the 5 clients, and each will produce a corresponding set of Circonus metrics

Finally, you will launch a simple application called 'hashiapp' via one of the server cluster machines (ns-1), and you can experiment with starting and stopping an application, adjusting the allocation count (there are versions with 3, and 10 allocationssd) and again, viewing the

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
vault read mysql/creds/hashiapp
```

```
vault write secret/hashiapp jwtsecret=secret
```

## Service Discovery with Consul

```
nomad plan jobs/consul.nomad
```

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

## Start Load Balancing with Fabio
Edit the jobs/fabio.nomad file and replace CIRCONUS_API_TOKEN with your Circonus api token

```
nomad run jobs/fabio.nomad
```

```
nomad status fabio
```

## Hashiapp Job

Submit the hashiapp service job.

```
nomad run jobs/hashiapp-v1-c3.nomad
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
or
```
while true; do curl -H "Host: hashiapp.com" http://<loadbalancer-ip>:9999/version; sleep 1; done
```

### Scaling Up

Run the `jobs/nomad run jobs/hashiapp-v1-c10.nomad` which starts 10 allocations instead of 3

```
nomad run jobs/hashiapp-v1-c10.nomad

```
Then you can switch to v2 by running
```
nomad run jobs/hashiapp-v2-c10.nomad

```


### Rolling Upgrades

Change up the jobs by running `jobs/hashiapp-v1-c3.nomad` or `jobs/hashiapp-v2-c3.nomad`

or via your local machine:
```
gcloud compute ssh ns-1 nomad run hashiconf-napa-2016/jobs/hashiapp-v2-c10.nomad
```
