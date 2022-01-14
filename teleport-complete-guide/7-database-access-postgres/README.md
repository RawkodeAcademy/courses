## PostgreSQL Access with Teleport

## Setup

- [ ] Running and working Teleport
- [ ] Running and working PostgreSQL
- [ ] Teleport CLI Authenticated (Can run `tsh status` and be authenticated)

## Exercise 1. Generate a DB Token

<details><summary>Answer</summary>
<p>
`tctl tokens add --type=db`
</p>
</details>

## Exercise 2. Generate Certificates for PostgreSQL TLS Mode

<details><summary>Answer</summary>
<p>
`tctl auth sign --format=db --host=postgres --out=server --ttl=2190h`
</p>
</details>

# Exercise 4. Configure PostgreSQL TLS Mode

<details><summary>Answer</summary>
<p>
## Move the Certs

You need to move the certs to a location that the `postgres` user has access to.

`/var/lib/postgresql/12/main` is a solid choice.

Remember to `chown postgres:postgres /var/lib/postgresql/12/main/server*`

You can then add the configuration provided by `tctl auth sign` to the PostgreSQL configuration file:

```
# /etc/postgresql/12/main/postgresql.conf
ssl = on
ssl_cert_file = '/var/lib/postgresql/12/main/server.crt'
ssl_key_file = '/var/lib/postgresql/12/main/server.key'
ssl_ca_file = '/var/lib/postgresql/12/main/server.cas'
```

```
# /etc/postgresql/12/main/pg_hba.conf
hostssl all             all             ::/0                    cert
hostssl all             all             0.0.0.0/0               cert
```
</p>
</details>

## Exercise 5. Add a Teleport Role for DB Access

```yaml
# db.role.yaml
kind: role
version: v4
metadata:
  name: db
spec:
  allow:
    db_labels:
      '*': '*'
    db_names:
    - '*'
    db_users:
    - '*'
```

```shell
tctl create -f db.role.yaml
tctl users add --roles=access,db myuser
```

## Exercise 5b. (Only Teleport Cloud) Modify Teleport Role to Include DB Impersonation

<details><summary>Answer</summary>
<p>
You can modify the Teleport roles via the UI or via the CLI.

## Using the CLI

```shell
tctl get roles > roles.yaml
vim roles.yaml
tctl create -f roles.yaml
```

This is the additional YAML needed to augment a role with the DB impersonation capabilities.

```yaml
allow:
  impersonate:
    users: ["Db"]
    roles: ["Db"]
```

</p>
</details>

## Exercise 6. Run a Teleport DB Proxy

<details><summary>Answer</summary>
<p>
```shell
teleport db start \
   --token=YOUR_TOKEN \
   --ca-pin=YOUR_CA_PIN \
   --auth-server=YOUR_AUTH_SERVER \
   --name=self-hosted-postgres \
   --protocol=postgres \
   --uri=YOUR_POSTGRES_URL_WITH_PORT \
   --labels=hosted=self
```
</p>
</details>


## Exercise 7. List Available Databases

<details><summary>Answer</summary>
<p>
```shell
tctl db ls
```
</p>
</details>

## Exercise 7. Login to PostgreSQL Database

<details><summary>Answer</summary>
<p>
```shell
tsh db login self-hosted-postgres
```
</p>
</details>

## Exercise 8. Connect to PostgreSQL Database

<details><summary>Answer</summary>
<p>
```shell
tsh db connect self-hosted-postgres
```
</p>
</details>

## Exercise 9. Connect to PostgreSQL with `psql`

<details><summary>Answer</summary>
<p>
```shell
tsh db config --format=cmd self-hosted-postgres
```
</p>
</details>

## Exercise 10. Connect to PostgreSQL with a GUI

<details><summary>Answer</summary>
<p>
```shell
tsh proxy db self-hosted-postgres
```
</p>
</details>
