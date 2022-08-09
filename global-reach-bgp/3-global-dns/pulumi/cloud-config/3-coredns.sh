#!/usr/bin/env sh
set -exu

# Install CoreDNS
curl -fsSL -o coredns.tgz https://github.com/coredns/coredns/releases/download/v1.9.3/coredns_1.9.3_linux_amd64.tgz
tar zxf coredns.tgz

# Already handled by archive, but that could change
chmod +x coredns

mv coredns /usr/bin/coredns
rm coredns.tgz

# Setup Zone
mkdir -p /etc/coredns

# These could be `git clone`'d
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

# Run CoreDNS with systemd

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
ExecStart=/usr/bin/coredns -conf=/etc/coredns/Corefile
ExecReload=/bin/kill -SIGUSR1 $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```
