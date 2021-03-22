terraform {
  required_version = ">= 0.13"
  required_providers {
    # aws = {
    #   source = "hashicorp/aws"
    # }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    # libvirt = {
    #   source  = "dmacvicar/libvirt"
    #   version = "~> 0.6.3"
    # }
    susepubliccloud = {
      # TF-UPGRADE-TODO
      #
      # No source detected for this provider. You must add a source address
      # in the following format:
      #
      # source = "your-registry.example.com/organization/susepubliccloud"
      #
      # For more information, see the provider source documentation:
      #
      # https://www.terraform.io/docs/configuration/providers.html#provider-source
      # TF-UPGRADE-TODO
      #
      # No source detected for this provider. You must add a source address
      # in the following format:
      #
      # source = "your-registry.example.com/organization/susepubliccloud"
      #
      # For more information, see the provider source documentation:
      #
      # https://www.terraform.io/docs/configuration/providers.html#provider-source
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
    template = {
      source = "hashicorp/template"
    }
  }
}
