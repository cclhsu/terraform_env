#cloud-config

# # set hostname
# hostname: $${hostname}

# set locale
locale: en_US.UTF-8

# set timezone
timezone: Etc/UTC

# # set root password
# chpasswd:
#   list: |
#     root:linux
#     $${username}:$${password}
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

runcmd:
  - /usr/bin/sed -ie "s#DHCLIENT_SET_HOSTNAME=\"no\"#DHCLIENT_SET_HOSTNAME=\"yes\"#" /etc/sysconfig/network/dhcp
  # - netconfig -f update
  # Since we are currently inside of the cloud-init systemd unit, trying to
  # start another service by either `enable --now` or `start` will create a
  # deadlock. Instead, we have to use the `--no-block-` flag.
  # The template machine should have been cleaned up, so no machine-id exists
  - dbus-uuidgen --ensure
  - systemd-machine-id-setup
  # With a new machine-id generated the journald daemon will work and can be restarted
  # Without a new machine-id it should be in a failed state
  - systemctl restart systemd-journald
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
${register_scc}
${register_rmt}
${commands}

bootcmd:
  - ip link set dev eth0 mtu 1500

final_message: "The system is finally up, after $UPTIME seconds"
