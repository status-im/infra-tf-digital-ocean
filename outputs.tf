locals {
  public_ips  = digitalocean_floating_ip.host[*].ip_address
  hostnames   = digitalocean_droplet.host[*].name
  droplet_ids = digitalocean_droplet.host[*].id
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
  value = zipmap(local.hostnames, local.droplet_ids )
}
