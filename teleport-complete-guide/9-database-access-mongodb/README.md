# mongoDB Access with Teleport

## Setup

- [ ] Running and working Teleport
- [ ] Running and working mongoDB
- [ ] Teleport CLI Authenticated (Can run `tsh status` and be authenticated)

## Exercise 1. Prepare mongoDB

First, we need to configure mongoDB's external user authentication with a new user.

This creates a user called `rawkode` with read/write access to the `admin` database.

```shell
db.getSiblingDB("$external").runCommand(
  {
    createUser: "CN=rawkode",
    roles: [
      { role: "readWriteAnyDatabase", db: "admin" }
    ]
  }
)
```

## Exercise 2. Create the Key/Cert for mongoDB TLS Mutual Authentication

```shell
tctl auth sign --format=mongodb --host=mongo.rawkode.sh --out=mongo --ttl=48h
```

## Exercise 3. Configure mongoDB with TLS Mutual Authentication

```yaml
# /etc/mongod.conf
net:
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/certs/mongo.crt
    CAFile: /etc/certs/mongo.cas
```

## Exercise 4. Generate a DB Token

`tctl tokens add --type=db`

## Exercise 5. Start Database Proxy

```shell
teleport db start \
    --token=?? \
    --auth-server=teleport.rawkode.sh:443 \
    --name=mongodb \
    --protocol=mongodb \
    --uri=mongodb://mongodb.rawkode.sh:27017
```

## Exercise 6. List Available Databases

```shell
tctl db ls
```

## Exercise 7. Login to mongoDB Database

```shell
tsh db login --db-user rawkode mongodb
```

## Exercise 8. Connect to mongoDB Database

```shell
tsh db connect mongodb rawkode
```

**Ru oh!**

Don't sweat, we've got this covered. The problem is that our mongoDB is only binding to 127.0.0.1 and that our DB proxy is connecting to mongoDB over its domain name, which resolves to the public IP.

We can fix this by telling the Linux server to resolve that domain name locally. Another option would be to have the public DNS resolve to 127.0.0.1.

Pick your own poison 🇿😊

```shell
# /etc/hosts
127.0.0.1 mongodb.rawkode.sh
```

## Exercise 9. Connect to mongoDB with CLI

```shell
tsh db config --format=cmd mongodb
```

## Exercise 10. Connect to mongoDB with a GUI

```shell
tsh proxy db mongodb
```
