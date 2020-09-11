resource "aws_instance" "etcds" {
  ami = data.susepubliccloud_image_ids.sles15sp2_chost_byos.ids[0]
  # associate_public_ip_address = false
  associate_public_ip_address = true
  count                       = var.etcds
  instance_type               = var.etcd_size
  key_name                    = aws_key_pair.kube.key_name
  source_dest_check           = false
  user_data                   = data.template_cloudinit_config.cfg.rendered
  iam_instance_profile        = length(var.iam_profile_etcd) == 0 ? local.aws_iam_instance_profile_etcd_terraform : var.iam_profile_etcd
  # subnet_id                   = aws_subnet.private.id
  subnet_id = aws_subnet.public.id

  depends_on = [
    # aws_route.private_nat_gateway,
    aws_internet_gateway.platform,
    aws_iam_instance_profile.etcd,
  ]

  tags = merge(
    local.tags,
    {
      "Name"  = "${var.stack_name}-etcd-${count.index}"
      "Class" = "Instance"
    },
  )

  vpc_security_group_ids = [
    aws_security_group.egress.id,
    aws_security_group.common.id,
    aws_security_group.etcd.id,
  ]

  lifecycle {
    create_before_destroy = true

    ignore_changes = [ami]
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
}
