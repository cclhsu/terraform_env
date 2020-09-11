# data "susepubliccloud_image_ids" "sles15sp2_chost_byos" {
#   cloud  = "amazon"
#   region = data.aws_region.current.name
#   state  = "active"

#   # USE SLES 15 SP2 Container host AMI - this is needed to avoid issues like bsc#1146774
#   name_regex = "suse-sles-15-sp2-chost-byos.*-hvm-ssd-x86_64"
# }

# data "aws_region" "current" {}

data "template_file" "worker_repositories" {
  count    = length(var.repositories)
  template = file("${path.module}/cloud-init/repository.tpl")

  vars = {
    repository_url  = element(values(var.repositories), count.index)
    repository_name = element(keys(var.repositories), count.index)
  }
}

data "template_file" "worker_register_scc" {
  count    = var.caasp_registry_code != "" && var.rmt_server_name == "" ? 1 : 0
  template = file("${path.module}/cloud-init/register-scc.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code
    rmt_server_name     = var.rmt_server_name
  }
}

data "template_file" "worker_register_rmt" {
  count    = var.rmt_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-rmt.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code
    rmt_server_name     = var.rmt_server_name
  }
}

data "template_file" "worker_register_suma" {
  count    = var.suma_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-suma.tpl")

  vars = {
    suma_server_name = var.suma_server_name
  }
}

data "template_file" "worker_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")

  vars = {
    packages = join(", ", var.packages)
  }
}

data "template_file" "worker_cloud-init" {
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    register_scc    = var.caasp_registry_code != "" && var.rmt_server_name == "" ? join("\n", data.template_file.worker_register_scc.*.rendered) : ""
    register_rmt    = var.rmt_server_name == "" ? join("\n", data.template_file.worker_register_rmt.*.rendered) : ""
    register_suma   = var.suma_server_name == "" ? join("\n", data.template_file.worker_register_sumba.*.rendered) : ""
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories    = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.worker_repositories.*.rendered)
    # packages        = join("\n", formatlist("  - %s", var.packages))
    commands = join("\n", data.template_file.worker_commands.*.rendered)
  }
}

data "template_cloudinit_config" "worker_cfg" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.worker_cloud-init[count.index].rendered
  }
}

resource "aws_iam_instance_profile" "worker" {
  name  = "${var.stack_name}-worker"
  role  = aws_iam_role.worker[count.index].name
  count = length(var.iam_profile_worker) == 0 ? 1 : 0
}

resource "aws_iam_role" "worker" {
  name        = "${var.stack_name}-worker"
  description = "IAM role needed by CPI on worker nodes"
  path        = "/"
  count       = length(var.iam_profile_worker) == 0 ? 1 : 0

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

resource "aws_iam_role_policy" "worker" {
  name  = "${var.stack_name}-worker"
  role  = aws_iam_role.worker[count.index].id
  count = length(var.iam_profile_worker) == 0 ? 1 : 0

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

# This security group is deliberately left empty,
# it's applied only to worker nodes.
#
# This security group is the only one with the
# `kubernetes.io/cluster/<cluster name>` tag, that makes it discoverable by the
# AWS CPI controller.
# As a result of that, this is going to be the security group the CPI will
# alter to add the rules needed to access the worker nodes from the AWS
# resources dynamically provisioned by the CPI (eg: load balancers).
resource "aws_security_group" "worker" {
  description = "security group rules for worker node"
  name        = "${var.stack_name}-worker"
  vpc_id      = aws_vpc.platform.id

  tags = merge(
    local.tags,
    {
      "Name"  = "${var.stack_name}-worker"
      "Class" = "SecurityGroup"
    },
  )
}

# https://www.terraform.io/docs/providers/aws/r/instance.html
resource "aws_instance" "worker" {

  count             = var.workers
  ami               = data.susepubliccloud_image_ids.sles15sp2_chost_byos.ids[0]
  instance_type     = var.worker_instance_type
  key_name          = aws_key_pair.kube.key_name
  source_dest_check = false

  availability_zone = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
  # associate_public_ip_address = false
  # subnet_id                 = aws_subnet.private[count.index % length(var.aws_availability_zones)].id
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[count.index % length(var.aws_availability_zones)].id
  user_data                   = data.template_cloudinit_config.worker_cfg.rendered
  iam_instance_profile        = length(var.iam_profile_worker) == 0 ? aws_iam_instance_profile.worker.0.name : var.iam_profile_worker
  # ebs_optimized          = true

  depends_on = [
    # aws_route.private_nat_gateway,
    aws_internet_gateway.platform,
    aws_iam_instance_profile.worker,
  ]

  vpc_security_group_ids = [
    aws_security_group.egress.id,
    aws_security_group.common.id,
    aws_security_group.worker.id,
  ]

  lifecycle {
    create_before_destroy = true

    ignore_changes = [ami]
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.worker_volume_size
    delete_on_termination = true
  }

  tags = merge(
    local.tags,
    {
      "Name"  = "${var.stack_name}-worker-${count.index}"
      "Class" = "Instance"
    },
  )
}
