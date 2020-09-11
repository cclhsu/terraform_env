variable "image_name" {
  default     = ""
  description = "Name of the image to use"
}

variable "internal_net" {
  default     = ""
  description = "Name of the internal network to be created"
}

variable "internal_subnet" {
  default     = ""
  description = "Name of the internal subnet to be created"
}

variable "internal_router" {
  default     = ""
  description = "Name of the internal router to be created"
}

variable "subnet_cidr" {
  default     = ""
  description = "CIDR of the subnet for the internal network"
}

variable "external_net" {
  default     = ""
  description = "Name of the external network to be used, the one used to allocate floating IPs"
}

variable "dnsdomain" {
  default     = ""
  description = "Name of DNS domain"
}

variable "dnsentry" {
  default     = false
  description = "DNS Entry"
}

variable "stack_name" {
  default     = "k8s"
  description = "Identifier to make all your resources unique and avoid clashes with other users of this terraform project"
}

variable "authorized_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into all the nodes"
}

variable "key_pair" {
  default     = ""
  description = "SSH key stored in openstack to create the nodes with"
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

variable "repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "packages" {
  type = list(string)

  default = [
    "kernel-default",
    "-kernel-default-base",
  ]

  description = "List of packages to install"
}

variable "username" {
  default     = "sles"
  description = "Username for the cluster nodes"
}

variable "password" {
  default     = "linux"
  description = "Password for the cluster nodes"
}

variable "caasp_registry_code" {
  default     = ""
  description = "SUSE CaaSP Product Registration Code"
}

variable "rmt_server_name" {
  default     = ""
  description = "SUSE Repository Mirroring Server Name"
}

variable "cpi_enable" {
  default     = false
  description = "Enable CPI integration with OpenStack"
}

variable "ca_file" {
  default     = ""
  description = "Used to specify the path to your custom CA file"
}

variable "etcds" {
  default     = 3
  description = "Number of etcd nodes"
}

variable "etcd_size" {
  default     = "m1.medium"
  description = "Size of the etcd nodes"
}

variable "etcds_vol_enabled" {
  default     = false
  description = "Attach persistent volumes to etcds"
}

variable "etcds_vol_size" {
  default     = 5
  description = "size of the volumes in GB"
}

variable "storages" {
  default     = 3
  description = "Number of storage nodes"
}

variable "storage_size" {
  default     = "m1.medium"
  description = "Size of the storage nodes"
}

variable "storages_vol_enabled" {
  default     = false
  description = "Attach persistent volumes to storages"
}

variable "storages_vol_size" {
  default     = 5
  description = "size of the volumes in GB"
}

variable "masters" {
  default     = 1
  description = "Number of master nodes"
}

variable "master_size" {
  default     = "m1.medium"
  description = "Size of the master nodes"
}

variable "masters_vol_enabled" {
  default     = false
  description = "Attach persistent volumes to masters"
}

variable "masters_vol_size" {
  default     = 5
  description = "size of the volumes in GB"
}

variable "workers" {
  default     = 2
  description = "Number of worker nodes"
}

variable "worker_size" {
  default     = "m1.medium"
  description = "Size of the worker nodes"
}

variable "workers_vol_enabled" {
  default     = false
  description = "Attach persistent volumes to workers"
}

variable "workers_vol_size" {
  default     = 5
  description = "size of the volumes in GB"
}
