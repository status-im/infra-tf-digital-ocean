/* DERIVED --------------------------------------*/
locals {
  stage = var.stage != "" ? var.stage : terraform.workspace
  dc    = "${var.provider_name}-${var.region}"
  /* always add SSH, WireGuard, and Consul to allowed ports */
  open_tcp_ports = concat(["22", "8301"], var.open_tcp_ports)
  open_udp_ports = concat(["51820", "8301"], var.open_udp_ports)
  /* tags for the dropplet */
  tags        = [local.stage, var.group, var.env]
  tags_sorted = sort(distinct(local.tags))
  /* pre-generated list of hostnames */
  hostnames = [for i in range(1, var.host_count + 1) :
    "${var.name}-${format("%02d", i)}.${local.dc}.${var.env}.${local.stage}"
  ]
}
/* RESOURCES ------------------------------------*/

resource "digitalocean_tag" "host" {
  name  = local.tags_sorted[count.index]
  count = length(local.tags_sorted)
}

/* Optional resource when vol_size is set */
resource "digitalocean_volume" "host" {
  name   = "data-${replace(local.hostnames[count.index], ".", "-")}"
  region = var.region
  size   = var.data_vol_size
  count  = var.data_vol_size > 0 ? var.host_count : 0
  lifecycle {
    prevent_destroy = true
    /* We do this to avoid destrying a volume unnecesarily */
    ignore_changes = [name]
  }
}

resource "digitalocean_droplet" "host" {
  name = local.hostnames[count.index]

  image    = var.image
  region   = var.region
  size     = var.type
  count    = var.host_count
  ssh_keys = var.ssh_keys

  tags = digitalocean_tag.host[*].id

  /* This can be optional, ugly as hell but it works */
  volume_ids = var.data_vol_size > 0 ? [digitalocean_volume.host[count.index].id] : null

  /* Ignore changes in attributes like image */
  lifecycle {
    ignore_changes = [image, ssh_keys]
  }
}

resource "digitalocean_floating_ip" "host" {
  droplet_id = digitalocean_droplet.host[count.index].id
  region     = digitalocean_droplet.host[count.index].region
  count      = var.host_count
  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_firewall" "host" {
  name        = "${var.name}.${local.dc}.${var.env}.${local.stage}"
  droplet_ids = digitalocean_droplet.host[*].id

  /* Allow ICMP pings */
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  /* TCP */
  dynamic "inbound_rule" {
    iterator = port
    for_each = local.open_tcp_ports
    content {
      protocol         = "tcp"
      port_range       = port.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  /* UDP */
  dynamic "inbound_rule" {
    iterator = port
    for_each = local.open_udp_ports
    content {
      protocol         = "udp"
      port_range       = port.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  /* Open for all outgoing connections */
  dynamic "outbound_rule" {
    iterator = protocol
    for_each = ["tcp", "udp"]
    content {
      protocol              = protocol.value
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "null_resource" "host" {
  for_each = zipmap(local.hostnames, digitalocean_droplet.host)

  /* Trigger bootstrapping on host or public IP change. */
  triggers = {
    droplet_id = each.value.id
    #floatin_ip_id  = digitalocean_floating_ip.host[count.index].id
  }

  /* Make sure everything is in place before bootstrapping. */
  depends_on = [
    digitalocean_volume.host,
    digitalocean_droplet.host,
    digitalocean_floating_ip.host,
    digitalocean_firewall.host,
  ]

  /* bootstraping access for later Ansible use */
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "${path.cwd}/ansible/bootstrap.yml"
      }

      hosts  = [each.value.ip_address]
      groups = [var.group]

      extra_vars = {
        hostname     = each.key
        ansible_user = var.ssh_user
        data_center  = local.dc
        stage        = local.stage
        env          = var.env
      }
    }
  }
}

resource "cloudflare_record" "host" {
  zone_id = var.cf_zone_id
  count   = var.host_count
  name    = digitalocean_droplet.host[count.index].name
  value   = digitalocean_floating_ip.host[count.index].ip_address
  type    = "A"
  ttl     = 3600
}

resource "ansible_host" "host" {
  inventory_hostname = digitalocean_droplet.host[count.index].name

  groups = ["${var.env}.${local.stage}", var.group, local.dc]
  count  = var.host_count

  vars = {
    ansible_host = digitalocean_floating_ip.host[count.index].ip_address
    hostname     = digitalocean_droplet.host[count.index].name
    region       = digitalocean_droplet.host[count.index].region
    dns_entry    = "${local.hostnames[count.index]}.${var.domain}"
    dns_domain   = var.domain
    data_center  = local.dc
    stage        = local.stage
    env          = var.env
  }
}
