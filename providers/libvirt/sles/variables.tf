variable "libvirt_uri" {
  type        = string
  default     = "qemu:///system"
  description = "URL of libvirt connection - default to localhost"
}

variable "libvirt_keyfile" {
  type        = string
  default     = ""
  description = "The private key file used for libvirt connection - default to none"
}

variable "pool" {
  type        = string
  default     = "default"
  description = "Pool to be used to store all the volumes"
}

variable "lb_image_uri" {
  type        = string
  default     = ""
  description = "URL of the lb image to use"
}

variable "image_uri" {
  type        = string
  default     = ""
  description = "URL of the image to use"
}

variable "lb_repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "stack_name" {
  type        = string
  default     = ""
  description = "Identifier to make all your resources unique and avoid clashes with other users of this terraform project"
}

variable "authorized_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into all the nodes"
}

variable "ntp_servers" {
  type        = list(string)
  default     = []
  description = "List of NTP servers to configure"
}

variable "dns_nameservers" {
  type        = list(string)
  default     = []
  description = "List of Name servers to configure"
}

variable "packages" {
  type = list(string)

  default = [
    "openssl",
    "kernel-default",
    "-kernel-default-base",
  ]

  description = "List of packages to install"
}

variable "username" {
  type        = string
  default     = "sles"
  description = "Username for the cluster nodes"
}

variable "password" {
  type        = string
  default     = "linux"
  description = "Password for the cluster nodes"
}

variable "caasp_registry_code" {
  type        = string
  default     = ""
  description = "SUSE CaaSP Product Registration Code"
}

variable "ha_registry_code" {
  type        = string
  default     = ""
  description = "SUSE Linux Enterprise High Availability Extension Registration Code"
}

variable "rmt_server_name" {
  type        = string
  default     = ""
  description = "SUSE Repository Mirroring Server Name"
}

variable "dns_domain" {
  type        = string
  default     = "sles.local"
  description = "Name of DNS Domain"
}

variable "network_cidr" {
  type        = string
  default     = "10.17.0.0/22"
  description = "Network used by the cluster"
}

variable "network_mode" {
  type        = string
  default     = "nat"
  description = "Network mode used by the cluster"
}

variable "network_name" {
  type        = string
  default     = ""
  description = "The virtual network name to use. If provided just use the given one (not managed by terraform), otherwise terraform creates a new virtual network resource"
}

variable "create_lb" {
  type        = bool
  default     = true
  description = "Create load balancer node exposing master nodes"
}

variable "create_http_server" {
  type        = bool
  default     = true
  description = "Create http server in load balancer node"
}

variable "lb_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a load balancer node"
}

variable "lb_vcpu" {
  type        = number
  default     = 1
  description = "Amount of virtual CPUs for a load balancer node"
}

variable "lb_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "etcds" {
  type        = number
  default     = 1
  description = "Number of etcd nodes"
}

variable "etcd_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a etcd node"
}

variable "etcd_vcpu" {
  type        = number
  default     = 1
  description = "Amount of virtual CPUs for a etcd node"
}

variable "etcd_disk_size" {
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "storages" {
  type        = number
  default     = 1
  description = "Number of storage nodes"
}

variable "storage_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a storage node"
}

variable "storage_vcpu" {
  type        = number
  default     = 1
  description = "Amount of virtual CPUs for a storage node"
}

variable "storage_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "masters" {
  type        = number
  default     = 1
  description = "Number of master nodes"
}

variable "master_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a master"
}

variable "master_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a master"
}

variable "master_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "workers" {
  type        = number
  default     = 2
  description = "Number of worker nodes"
}

variable "worker_memory" {
  type        = number
  default     = 2048
  description = "Amount of RAM for a worker"
}

variable "worker_vcpu" {
  type        = number
  default     = 2
  description = "Amount of virtual CPUs for a worker"
}

variable "worker_disk_size" {
  type        = number
  default     = 32212254720
  description = "Disk size (in bytes)"
}

variable "hostname_from_dhcp" {
  type        = bool
  default     = true
  description = "Set node's hostname from DHCP server"
}

variable "cpi_enable" {
  type        = bool
  default     = false
  description = "Enable CPI integration with Azure"
}
