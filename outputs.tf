locals = {
  public_ips = "${digitalocean_droplet.host.*.ipv4_address}"
  hostnames  = "${digitalocean_droplet.host.*.name}"
}

output "public_ips" {
  value = ["${local.public_ips}"]
}

output "hostnames" {
  value = ["${local.hostnames}"]
}

output "hosts" {
  value = "${zipmap(local.hostnames, local.public_ips)}"
}
