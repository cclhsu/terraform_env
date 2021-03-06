#cloud-config
ssh_authorized_keys:
${authorized_keys}
# - github:cclhsu

k3os:
  # k3s_args:
  # - "agent"
  labels:
    k3os.io/upgrade: enabled
    k3s-upgrade: true
  dns_nameservers:
  - 8.8.8.8
  - 1.1.1.1
  ntp_servers:
  - 0.us.pool.ntp.org
  - 1.us.pool.ntp.org

# ssh_authorized_keys:
# $${authorized_keys}
# # write_files:
# # - encoding: ""
# #   content: |-
# #     #!/bin/bash
# #     echo hello, local service start
# #   owner: root
# #   path: /etc/local.d/example.start
# #   permissions: '0755'
# hostname: $${hostname}
# # init_cmd:
# # - "echo hello, init command"
# # boot_cmd:
# # - "echo hello, boot command"
# # run_cmd:
# # - "echo hello, run command"

# k3os:
#   # data_sources:
#   # - aws
#   # - cdrom
#   # modules:
#   # - kvm
#   # - nvme
#   # sysctl:
#   #   kernel.printk: "4 4 1 7"
#   #   kernel.kptr_restrict: "1"
#   # dns_nameservers:
#   # - 8.8.8.8
#   # - 1.1.1.1
#   # ntp_servers:
#   # - 0.us.pool.ntp.org
#   # - 1.us.pool.ntp.org
#   # wifi:
#   # - name: home
#   #   passphrase: mypassword
#   # - name: nothome
#   #   passphrase: somethingelse
#   password: $${password}
#   # server_url: https://someserver:6443
#   # token: TOKEN_VALUE
#   # labels:
#   #   region: us-west-1
#   #   somekey: somevalue
#   # k3s_args:
#   # - server
#   # - "--disable-agent"
#   # environment:
#   #   http_proxy: http://myserver
#   #   https_proxy: http://myserver
#   # taints:
#   # - key1=value1:NoSchedule
#   # - key1=value1:NoExecute