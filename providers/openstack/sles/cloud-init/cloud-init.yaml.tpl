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

# # set root password
# ssh_pwauth: True
# chpasswd:
#   list: |
#     root:linux
#     ${username}:${password}
#   expire: False

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

# # need to disable gpg checks because the cloud image has an untrusted repo
# zypper:
#   repos:
# $${repositories}
#   config:
#     gpgcheck: "off"
#     solver.onlyRequires: "true"
#     download.use_deltarpm: "true"
# need to remove the standard docker packages that are pre-installed on the
# cloud image because they conflict with the kubic- ones that are pulled by
# the kubernetes packages
# WARNING!!! Do not use cloud-init packages module when SUSE CaaSP Registration
# Code is provided. In this case, repositories will be added in runcmd module
# with SUSEConnect command after packages module is ran
# packages:

bootcmd:
  - ip link set dev eth0 mtu 1500

runcmd:
  # workaround for bsc#1119397 . If this is not called, /etc/resolv.conf is empty
  - netconfig -f update
  # Workaround for bsc#1138557 . Disable root and password SSH login
  - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -i -e '/^#ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
  - sed -i -e '/^#PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
  - sshd -t || echo "ssh syntax failure"
  - systemctl restart sshd
  # - ulimit -c unlimited
  # - install -m 1777 -d /var/lib/systemd/coredump
  # - echo '|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %e' > /proc/sys/kernel/core_pattern
  # - /usr/lib/systemd/systemd-sysctl --prefix kernel.core_pattern
  # - echo 'kernel.core_pattern=|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %e' >> /etc/sysctl.d/50-coredump.conf
  # - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/50-coredump.conf
  # - /sbin/rcapparmor stop || true
  # - echo 'kernel.suid_dumpable = 2' >> /etc/sysctl.d/suid_dumpable.conf
  # - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/suid_dumpable.conf
  - /sbin/swapoff -a
  - echo 'vm.swappiness = 0' >> /etc/sysctl.d/swappiness.conf
  - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/swappiness.conf
  - /usr/bin/sed -i 's/.*swap.*/#&/' /etc/fstab
  - /usr/bin/systemctl restart systemd-sysctl
${register_scc}
${register_rmt}
${commands}

final_message: "The system is finally up, after $UPTIME seconds"
