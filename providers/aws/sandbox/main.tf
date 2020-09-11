locals {
  basic_tags = merge(
    {
      "Name"        = var.stack_name
      "Environment" = var.stack_name
    },
    var.tags,
  )

  tags = local.basic_tags
  # tags = merge(
  #   local.basic_tags,
  #   {
  #     format("kubernetes.io/cluster/%v", var.stack_name) = "SUSE-terraform"
  #   },
  # )
}

# https://www.terraform.io/docs/providers/aws/index.html
provider "aws" {
  profile = "default"
}

data "susepubliccloud_image_ids" "sles15sp2_chost_byos" {
  cloud  = "amazon"
  region = data.aws_region.current.name
  state  = "active"

  # USE SLES 15 SP2 Container host AMI - this is needed to avoid issues like bsc#1146774
  name_regex = "suse-sles-15-sp2-chost-byos.*-hvm-ssd-x86_64"
}

data "aws_region" "current" {}

resource "aws_key_pair" "kube" {
  key_name   = "${var.stack_name}-keypair"
  public_key = element(var.authorized_keys, 0)
}

// list of availability_zones which can be access from the current region
data "aws_availability_zones" "availability_zones" {
  state = "available"
}
