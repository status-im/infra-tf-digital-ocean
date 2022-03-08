locals {
  public_ips  = [for a in digitalocean_floating_ip.host : a.ip_address]
  droplet_ids = [for d in digitalocean_droplet.host : d.id]
}

output "public_ips" {
  value = local.public_ips
}

output "hostnames" {
  value = local.hostnames
}

output "hosts" {
  value = zipmap(local.hostnames, local.public_ips)
}

output "ids" {
  value = zipmap(local.hostnames, local.droplet_ids)
}
