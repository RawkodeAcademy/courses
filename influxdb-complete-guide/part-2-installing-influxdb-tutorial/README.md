# Installing InfluxDB 2

This tutorial is available on [YouTube](https://www.youtube.com/watch?v=G0OM6ZNV2rQ).

## Homebrew on macOS

```shell
brew install influxdb
```

## Debian and Ubuntu

```shell
wget -qO- https://repos.influxdata.com/influxdb.key | gpg --dearmor > /etc/apt/trusted.gpg.d/influxdb.gpg
export DISTRIB_ID=$(lsb_release -si); export DISTRIB_CODENAME=$(lsb_release -sc)
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" > /etc/apt/sources.list.d/influxdb.list

apt update && apt install -y influxdb2
```

## RedHat

```shell
cat <<EOF | tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

dnf install influxdb2
```

## Docker

```shell
docker volume create influxdb
docker container run -p 8086:8086 -v influxdb:/var/lib/influxdb influxdb:2.0.7
```

### Kubernetes with Helm

```shell
helm repo add influxdata https://helm.influxdata.com/
helm upgrade --install my-release influxdata/influxdb2
```
