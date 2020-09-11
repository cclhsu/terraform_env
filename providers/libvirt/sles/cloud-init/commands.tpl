# FIXME: wait to prevent race condition that makes zypper install to fail
# retriving metadata from repositories
  - sleep 30
  - zypper -n install ${packages}
  - ulimit -c unlimited
  - install -m 1777 -d /var/lib/systemd/coredump
  - echo '|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %e' > /proc/sys/kernel/core_pattern
  - /usr/lib/systemd/systemd-sysctl --prefix kernel.core_pattern
  - echo 'kernel.core_pattern=|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %e' >> /etc/sysctl.d/50-coredump.conf
  - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/50-coredump.conf
  - /sbin/rcapparmor stop
  - echo 'kernel.suid_dumpable = 2' >> /etc/sysctl.d/suid_dumpable.conf
  - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/suid_dumpable.conf
  - /sbin/swapoff -a
  - echo 'vm.swappiness = 0' >> /etc/sysctl.d/swappiness.conf
  - /usr/lib/systemd/systemd-sysctl /etc/sysctl.d/swappiness.conf
  - /usr/bin/sed -i 's/.*swap.*/#&/' /etc/fstab
  - /usr/bin/systemctl restart systemd-sysctl
  - echo '$(date) - hello world!' > /tmp/hello.txt
