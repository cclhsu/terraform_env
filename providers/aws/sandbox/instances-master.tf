# data "susepubliccloud_image_ids" "sles15sp2_chost_byos" {
#   cloud  = "amazon"
#   region = data.aws_region.current.name
#   state  = "active"

#   # USE SLES 15 SP2 Container host AMI - this is needed to avoid issues like bsc#1146774
#   name_regex = "suse-sles-15-sp2-chost-byos.*-hvm-ssd-x86_64"
# }

# data "aws_region" "current" {}

data "template_file" "master_repositories" {
  count    = length(var.repositories)
  template = file("${path.module}/cloud-init/repository.tpl")

  vars = {
    repository_url  = element(values(var.repositories), count.index)
    repository_name = element(keys(var.repositories), count.index)
  }
}

data "template_file" "master_register_scc" {
  count    = var.caasp_registry_code != "" && var.rmt_server_name == "" ? 1 : 0
  template = file("${path.module}/cloud-init/register-scc.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code
    rmt_server_name     = var.rmt_server_name
  }
}

data "template_file" "master_register_rmt" {
  count    = var.rmt_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-rmt.tpl")

  vars = {
    rmt_server_name = var.rmt_server_name
  }
}

data "template_file" "master_register_suma" {
  count    = var.suma_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-suma.tpl")

  vars = {
    suma_server_name = var.suma_server_name
  }
}

data "template_file" "master_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")

  vars = {
    packages = join(", ", var.packages)
  }
}

data "template_file" "master_cloud-init" {
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    register_scc    = var.caasp_registry_code != "" && var.rmt_server_name == "" ? join("\n", data.template_file.master_register_scc.*.rendered) : ""
    register_rmt    = var.rmt_server_name == "" ? join("\n", data.template_file.master_register_rmt.*.rendered) : ""
    register_suma   = var.suma_server_name == "" ? join("\n", data.template_file.master_register_sumba.*.rendered) : ""
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories    = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.repositories.*.rendered)
    # packages        = join("\n", formatlist("  - %s", var.packages))
    commands = join("\n", data.template_file.master_commands.*.rendered)
  }
}

data "template_cloudinit_config" "master_cfg" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.master_cloud-init[count.index].rendered
  }
}

resource "aws_iam_instance_profile" "master" {
  name  = "${var.stack_name}-master"
  role  = aws_iam_role.master[count.index].name
  count = length(var.iam_profile_master) == 0 ? 1 : 0
}

resource "aws_iam_role" "master" {
  name        = "${var.stack_name}-master"
  description = "IAM role needed by CPI on master nodes"
  path        = "/"
  count       = length(var.iam_profile_master) == 0 ? 1 : 0

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "master" {
  name  = "${var.stack_name}-master"
  role  = aws_iam_role.master[count.index].id
  count = length(var.iam_profile_master) == 0 ? 1 : 0

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "iam:CreateServiceLinkedRole",
        "kms:DescribeKey"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_security_group" "master" {
  description = "security rules for master nodes"
  name        = "${var.stack_name}-master"
  vpc_id      = aws_vpc.platform.id

  tags = merge(
    local.tags,
    {
      "Name"  = "${var.stack_name}-master"
      "Class" = "SecurityGroup"
    },
  )

  # etcd - internal
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
    description = "etcd"
  }

  # api-server - everywhere
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "kubernetes api-server"
  }
}

# https://www.terraform.io/docs/providers/aws/r/instance.html
resource "aws_instance" "master" {

  count             = var.masters
  ami               = data.susepubliccloud_image_ids.sles15sp2_chost_byos.ids[0]
  instance_type     = var.master_instance_type
  key_name          = aws_key_pair.kube.key_name
  source_dest_check = false

  availability_zone = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
  # associate_public_ip_address = false
  # subnet_id                 = aws_subnet.private[count.index % length(var.aws_availability_zones)].id
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[count.index % length(var.aws_availability_zones)].id
  user_data                   = data.template_cloudinit_config.master_cfg.rendered
  iam_instance_profile        = length(var.iam_profile_master) == 0 ? aws_iam_instance_profile.master.0.name : var.iam_profile_master
  # ebs_optimized          = true

  depends_on = [
    aws_internet_gateway.platform,
    aws_iam_instance_profile.master,
  ]

  vpc_security_group_ids = [
    aws_security_group.egress.id,
    aws_security_group.common.id,
    aws_security_group.master.id,
  ]

  lifecycle {
    create_before_destroy = true

    ignore_changes = [ami]
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.master_volume_size
    delete_on_termination = true
  }

  tags = merge(
    local.tags,
    {
      "Name"  = "${var.stack_name}-master-${count.index}"
      "Class" = "Instance"
    },
  )
}
