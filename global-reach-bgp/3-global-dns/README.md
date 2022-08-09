# Global DNS

In this workshop, we're going to deploy CoreDNS to three metros within the Equinix Metal network.

In-order to following along with this workshop, you need an [Equinix Metal](https://rawkode.link/metal) account. Use the code "rawkode" when signing up to claim your 200USD FREE credits.

**There's a video of this workshop being completed. If you get stuck, or just want to follow along, you can find it here.**

## Getting a Global IP

The first thing we need to do is reserve an IPv4 Global IP from Equinix.

- Browse to the [Equinix Console](https://console.equinix.com)
- Select "IPs & Networks -> IPs" from the main menu
- Select "Reserve IP Addresses" button
- Select "Global IPv4"
- Select quantity of 1
- Submit request

## Deploying the Servers

Next up, deploy three Ubuntu servers to the metros of your choice. I'll be using Chicago, London, and Sydney.

- Select "Servers -> OnDemand" from the main menu
- Configure two servers
  - Select metro (remember to use two different, far apart metros)
  - Select instance size (c3.small if available)
  - Select Ubuntu
  - Deploy now

## Advertising our IP with bird

Repeat these steps for each server:

- SSH to your server
  - You can find the IP addresses (and root passwords) from the servers page on the main menu
  - Update `apt` database with `apt update`
  - Install `bird` and `nginx` with `apt install bird`
  - Install `python` so we can leverage the `network-helpers` provided by Equinix: `apt install python3.6 python3-pip git`

### Configure the Interface

Make sure you swap `x.x.x.x` with your Global IPv4 address.

```shell
cat >>/etc/network/interfaces <<EOF
auto lo:0
iface lo:0 inet static
  address x.x.x.x
  netmask 255.255.255.255
EOF

ifup lo:0
```

### Fetching BGP Config

In-order to advertise our IPv4 address within the Equinix network, we need to find out where the top of rack switches are. This is made available to you via the Equinix Metadata service.

```shell
curl https://metadata.platformequinix.com/metadata \
    | jq '.bgp_neighbors[0] | { customer_ip: .customer_ip, customer_as: .customer_as, multihop: .multihop, peer_ips: .peer_ips, peer_as: .peer_as }'
```

We'll also need the ensure we have the appropriate routes in our routing table for the IBX gateway. Remember to substitute `x.x.x.x` and `.x.x.x.z` with your peer IPs from the command above. They'll likely be `169.254.255.1` and `169.254.255.2`, though this could change at anytime.

```shell
curl https://metadata.platformequinix.com/metadata \
    | jq -r '.network.addresses[] | select(.public == true and .address_family == 4) | { gateway: .gateway }'

ip route add x.x.x.x via ${GATEWAY_IP}
ip route add x.x.x.z via ${GATEWAY_IP}
```

### Configuring Bird

Equinix provide some helpers so you don't need to manually configure bird yourself, so lets fetch them and run them.

```shell
cd /opt
git clone https://github.com/packethost/network-helpers.git
cd network-helpers
pip3 install jmespath
pip3 install -e .
./configure.py -r bird | tee /etc/bird/bird.conf
systemctl restart bird
```

## Testing it Works

You can open a bird console with `birdc` and run the query `show protocols all neighbor_v4_1` to see if we're successfully advertising our Global IPv4 address with BGP correctly.

```shell
bird


bird> show protocols all neighbor_v4_1
```

Once you've deployed both servers, you can test the latency from multiple regions to ensure its routed correctly.

You can use an online service like [locaping](https://locaping.com/traceroute) or test it manually with `traceroute`. Remember to substitute `x.x.x.x` for your Global IPv4 address.

```shell
traceroute x.x.x.x
```

## Installing CoreDNS

```shell
curl -fsSL -o coredns.tgz https://github.com/coredns/coredns/releases/download/v1.9.3/coredns_1.9.3_linux_amd64.tgz
tar zxvf coredns.tgz
mv coredns /usr/local/bin/
```

## Adding Your Domain

```shell
mkdir -p /etc/coredns

cat >>/etc/coredns/yourfirstdomain.com <<EOF
\$ORIGIN yourfirstdomain.com.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

www     IN A     127.0.0.1
        IN AAAA  ::1
EOF

cat >>/etc/coredns/Corefile <<EOF
.:153 {
    forward . 8.8.8.8
    log
    errors
    cache
}

yourfirstdomain.com.:153 {
    file /etc/coredns/yourfirstdomain.com
    log
}
EOF
```

## Managing CoreDNS with systemd

```shell
cat >/etc/systemd/system/coredns.service <<EOF
[Unit]
Description=CoreDNS DNS server
Documentation=https://coredns.io
After=network.target

[Service]
PermissionsStartOnly=true
LimitNOFILE=1048576
LimitNPROC=512
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
User=coredns
WorkingDirectory=/etc/coredns
ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/Corefile
ExecReload=/bin/kill -SIGUSR1 $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```