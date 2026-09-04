output "south_instance_ids" {
  value = module.south_ec2.instance_ids
}

output "south_public_ips" {
  value = module.south_ec2.public_ips
}

output "south_private_ips" {
  value = module.south_ec2.private_ips
}

output "east_instance_ids" {
  value = module.east_ec2.instance_ids
}

output "east_public_ips" {
  value = module.east_ec2.public_ips
}

output "east_private_ips" {
  value = module.east_ec2.private_ips
}