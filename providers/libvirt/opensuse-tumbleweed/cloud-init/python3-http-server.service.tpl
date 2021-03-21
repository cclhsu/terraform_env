# /usr/lib/systemd/system
[Unit]
Description=Python3 HTTP.Server
Documentation=https://docs.python.org/3/library/http.server.html
After=network.target

[Service]
Type=simple
WorkingDirectory=/var/www/html/
ExecStart=/usr/bin/python3 -m http.server 80
ExecStop=/bin/kill -HUP $MAINPID
ExecReload=/bin/kill -HUP $MAINPID

# Sandboxing features
PrivateTmp=yes
NoNewPrivileges=true
ProtectSystem=strict
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_DAC_READ_SEARCH
RestrictNamespaces=uts ipc pid user cgroup
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
PrivateDevices=yes
RestrictSUIDSGID=true
#IPAddressAllow=192.168.1.0/24

[Install]
WantedBy=multi-user.target
