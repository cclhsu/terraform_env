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

# users:
#   - name: $${username}
#     passwd: $${password}
#     ssh-authorized-keys:
#       $${authorized_keys}
#     sudo: ['ALL=(ALL) NOPASSWD:ALL']
#     groups: sudo
#     shell: /bin/bash

# # set root password
# ssh_pwauth: True
# chpasswd:
#   list: |
#     root:linux
#     $${username}:$${password}
#   expire: False

# Inject the public keys
ssh_authorized_keys:
${authorized_keys}

# NOT WORKING for AWS and AZURE
# ntp:
#   enabled: true
#   ntp_client: chrony
#   config:
#     confpath: /etc/chrony.d/chrony.conf
#   servers:
# $${ntp_servers}


# NOT WORKING for AWS and AZURE
# # https://www.thinbug.com/q/49826047
# manage_resolv_conf: true
# resolv_conf:
#   nameservers:
# $${dns_nameservers}

# # need to disable gpg checks because the cloud image has an untrusted repo
# zypper:
#   repos:
# $${repositories}
#   config:
#     gpgcheck: "off"
#     solver.onlyRequires: "true"
#     download.use_deltarpm: "true"

# WARNING!!! Do not use cloud-init packages module when SUSE CaaSP Registration
# Code is provided. In this case, repositories will be added in runcmd module
# with SUSEConnect command after packages module is ran
# packages:
# $${packages}

bootcmd:
  - ip link set dev eth0 mtu 1500

runcmd:
${register_scc}
${register_rmt}
${register_suma}
${repositories}
${commands}

final_message: "The system is finally up, after $UPTIME seconds"
