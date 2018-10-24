output "public_ips" {
  value = ["${digitalocean_droplet.host.*.ipv4_address}"]
}
