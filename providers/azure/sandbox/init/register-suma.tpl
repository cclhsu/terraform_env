curl --tlsv1.2 --insecure --connect-timeout 10 https://${suma_server_name}/pub/bootstrap/bootstrap.sh --output /tmp/bootstrap.sh
chmod +x /tmp/bootstrap.sh
sh /tmp/bootstrap.sh
