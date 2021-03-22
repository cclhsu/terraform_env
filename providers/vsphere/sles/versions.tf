terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.6.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0.0"
    }
    # null = {
    #   source = "hashicorp/null"
    # }
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.0.0"
    # }
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
    template = {
      source = "hashicorp/template"
    }
    null = {
      source = "hashicorp/null"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}
