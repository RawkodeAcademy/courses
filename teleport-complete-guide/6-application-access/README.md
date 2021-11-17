# Application Access

**NOTE**: Search and replace `rawkode.sh` with a domain name you control!

## Setup

To work through this workshop, you'll need access to some servers. This directory contains some Pulumi code to spin up 2 Linodes, however you can use containers, VMs on any cloud, or even bare metal.

## Exercise 1. Create DNS Records for your Linodes

- [ ] Create `t.rawkode.sh` for your Teleport server Linode.
- [ ] Create `*.t.rawkode.sh` for your Teleport server Linode.
- [ ] Create `w1.rawkode.sh` for your Teleport worker Linode.

## Exercise 2. Create a Teleport Server

SSH onto the Teleport Server Linode and run the following commands to get the Teleport server up-and-running.

**NOTE:** Remember to swap the DNS name for something you control.

```shell
hostnamectl set-hostname t.rawkode.sh

curl https://deb.releases.teleport.dev/teleport-pubkey.asc | sudo apt-key add -
add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'
apt-get update
apt install teleport

teleport configure --acme --acme-email=david@rawkode.com --cluster-name=t.rawkode.sh -o file

systemctl start teleport
```

This will generate a config that will look like so:

```yaml
version: v2

teleport:
  nodename: t.rawkode.sh
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
    format:
      output: text
  ca_pin: []
  diag_addr: ""

auth_service:
  enabled: "yes"
  listen_addr: 0.0.0.0:3025
  cluster_name: t.rawkode.sh
  proxy_listener_mode: multiplex

ssh_service:
  enabled: "yes"
  labels:
    env: example
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s

proxy_service:
  enabled: "yes"
  web_listen_addr: 0.0.0.0:443
  public_addr: t.rawkode.sh:443
  https_keypairs: []
  acme:
    enabled: "yes"
    email: david@rawkode.com
```

## Exercise 2. Add Static Node Token

Extend the `auth_service` section with our static join token. Static join tokens are insecure and only used for convenience in this workshop. For short-lived, more secure, tokens, [checkout the docs](https://goteleport.com/docs/setup/admin/adding-nodes).

```yaml
    tokens:
    # This static token allows new hosts to join the cluster as "proxy" or "node"
    - "proxy,node:rawkode-workshop"
```

It should look something like:

```yaml
auth_service:
  enabled: "yes"
  listen_addr: 0.0.0.0:3025
  cluster_name: t.rawkode.sh
  proxy_listener_mode: multiplex
  tokens:
  - "app,proxy,node:rawkode-workshop"
```

## Exercise 3. Create Admin User

```shell
tctl users add rawkode --roles=editor,access --logins=root
```

## Exercise 4. Join Node to Cluster

Using a static authentication token, join your other available nodes to the Teleport cluster.

SSH on to the worker Linode and running the following commands to join the cluster.

```shell
hostnamectl set-hostname w1.rawkode.sh

curl https://deb.releases.teleport.dev/teleport-pubkey.asc | sudo apt-key add -
add-apt-repository 'deb https://deb.releases.teleport.dev/ stable main'
apt-get update
apt install teleport

cat <<EOF >/etc/teleport.yaml
teleport:
  auth_token: "rawkode-workshop"
  auth_servers:
    - "t.rawkode.sh:3025"

auth_service:
  enabled: "no"
  
ssh_service:
  enabled: "yes"
  labels:
    env: example
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s
EOF

systemctl start teleport
```

## Exercise 5. Enable Debug App

Teleport ships with a debug app that dumps some environment variables for you to inspect.

- Enable the debug application
- Browse to the debug application
- Decode the JWT at [jwt.io](https://jwt.io)

<details>
  <summary>Solution</summary>

  On the Teleport server, edit the `/etc/teleport.yaml` file to include `debug_app: true` under `app_service`.

  ```yaml
  app_service:
    enabled: true
    debug_app: true
  ```

  Restart Teleport with `systemctl restart teleport`.
</details>


## Exercise 6. Nginx

- Install `nginx` on the Teleport server
- Add nginx as an application to the Teleport cluster
- Configure nginx to only respond to private IP4v addresses
- Confirm nginx still works

<details>
  <summary>Solution</summary>
  
  ### Install `nginx` on the Teleport server

  ```shell
  apt install nginx
  ```
  ### Add nginx as an application to the Teleport cluster

  ```yaml
  app_service:
    enabled: "true"
    apps:
    - name: "nginx"
      uri: "http://127.0.0.1:80"
  ```


  ### Configure nginx to only respond to private IP4v addresses

  ```
  #/etc/nginx/sites-enabled/default
  server {
    listen PRIVATE_IP:80; # or listen 127.0.0.1:80;
  }
  ```

  ### Confirm nginx still works

  You should be able to browse to `https://nginx.t.rawkode.sh`, but you should get a connection error when hitting the `NODE_IP` on port 80.
</details>


## Exercise 7. Grafana

- Install Docker on Teleport server Linode.
- Pull and run Grafana container image, exposing port 3000, ensuring the port isn't available on the public IPv4 address.
- Add Grafana as an application to the Teleport cluster, overriding the DNS name to be `g.t.rawkode.sh`.

<details>
  <summary>Solution</summary>
  
  ### Install Docker on Teleport server Linode

  ```shell
  curl -fsSL https://get.docker.com | sh
  ```

  ### Pull and run Grafana container image, exposing port 3000, ensuring the port isn't available on the public IPv4 address.

  ```shell
  docker container run -d -p 127.0.0.1:3000:3000 grafana/grafana
  ```

  ### Add Grafana as an application to the Teleport cluster, overriding the DNS name to be `g.t.rawkode.sh`.

  ```yaml
  app_service:
    enabled: "yes"
    apps:
    - name: "grafana"
      uri: "http://127.0.0.1:3000"
      # This overrides the default generated, using name, public address.
      public_addr: "g.t.rawkode.sh"
  ```

</details>

## Exercise 8. Semi Public Access

- Modify nginx virtual-host to block non-local traffic to admin page
- Add "secret" application to `app_service` of Teleport

### Secret App Setup

```shell
apt update && apt install nginx
echo "ADMIN PAGE" > /var/www/html/admin.html
systemctl restart nginx
```

<details>
  <summary>Solution</summary>

  ### Modify nginx virtual-host to block non-local traffic to admin page

  ```
  location ~ /(admin.html) {
    allow 127.0.0.1;

    deny all;

    try_files $uri @proxy;
  }
  ```


  ### Add "secret" application to `app_service` of Teleport

  When running Teleport process as an application proxy, it's much easier to create a new unit file for `systemd` and use `teleport app start`.

  Teleport doesn't support running the `app_service` along side the `proxy_service` without the `auth_service`; so you need additional processes.

  This currently needs better documentation, feel free to follow [this issue for more](https://github.com/gravitational/teleport/issues/5442).

  ```shell
  teleport app start --name=admin --uri="http://localhost:80/" --token=rawkode-workshop --auth-server=t.rawkode.sh:443
  ```

</details>


## Exercise 9. CLI / Local / API Access

- Use `tctl` to allow our "secret" application to be consumed locally
- Use `tctl` to allow the "dumper" application to be consumed locally
