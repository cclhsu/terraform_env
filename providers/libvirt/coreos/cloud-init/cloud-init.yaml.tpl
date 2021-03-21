#cloud-config
# vim: syntax=yaml
#
# ***********************
#   ---- for more examples look at: ------
# ---> https://cloudinit.readthedocs.io/en/latest/topics/examples.html
# ---> https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
# ******************************
#
# This is the configuration syntax that the write_files module
# will know how to understand. encoding can be given b64 or gzip or (gz+b64).
# The content will be decoded accordingly and then written to the path that is
# provided.
#
# Note: Content strings here are truncated for example purposes.

# set locale
locale: en_US.UTF-8

# set timezone
timezone: Etc/UTC

users:
  - name: ${username}
    ssh-authorized-keys:
      ${authorized_keys}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

# set root password
ssh_pwauth: True
chpasswd:
  list: |
    root:linux
    ${username}:${password}
  expire: False

# Inject the public keys
ssh_authorized_keys:
${authorized_keys}

ntp:
  enabled: true
  ntp_client: chrony
  config:
    confpath: /etc/chrony.conf
  servers:
${ntp_servers}

# # https://www.thinbug.com/q/49826047
# manage_resolv_conf: true
# resolv_conf:
#   nameservers:
# $${dns_nameservers}

packages:
${packages}

# set hostname
hostname: ${hostname}

bootcmd:
  - ip link set dev eth0 mtu 1500

runcmd:
  # Set node's hostname from DHCP server
  - netconfig -f update
  - sed -i -e '/^DHCLIENT_SET_HOSTNAME/s/^.*$/DHCLIENT_SET_HOSTNAME=\"${hostname_from_dhcp}\"/' /etc/sysconfig/network/dhcp
  - systemctl restart wicked
  - sed -i 's/#GSSAPIAuthentication no/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
  - sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
${commands}

final_message: "The system is finally up, after $UPTIME seconds"
