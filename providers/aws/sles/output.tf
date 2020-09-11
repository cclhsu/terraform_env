# output "etcds_public_ip" {
#   value = zipmap(
#     aws_instance.etcds.*.id,
#     aws_instance.etcds.*.public_ip,
#   )
# }

output "etcds_private_dns" {
  value = zipmap(
    aws_instance.etcds.*.id,
    aws_instance.etcds.*.private_dns,
  )
}

# output "storages_public_ip" {
#   value = zipmap(
#     aws_instance.storages.*.id,
#     aws_instance.storages.*.public_ip,
#   )
# }

output "storages_private_dns" {
  value = zipmap(
    aws_instance.storages.*.id,
    aws_instance.storages.*.private_dns
  )
}

output "masters_public_ip" {
  value = zipmap(
    aws_instance.master.*.id,
    aws_instance.master.*.public_ip,
  )
}

output "masters_private_dns" {
  value = zipmap(
    aws_instance.master.*.id,
    aws_instance.master.*.private_dns,
  )
}

# output "workers_public_ip" {
#   value = zipmap(
#     aws_instance.workers.*.id,
#     aws_instance.workers.*.public_ip,
#   )
# }

output "workers_private_dns" {
  value = zipmap(
    aws_instance.workers.*.id,
    aws_instance.workers.*.private_dns
  )
}
