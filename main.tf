/* DERIVED --------------------------------------*/
locals {
  stage = var.stage != "" ? var.stage : terraform.workspace
  dc    = "${var.provider_name}-${var.region}"
  sufix = "${local.dc}.${var.env}.${local.stage}"
  /* tags for the dropplet */
  tags        = [local.stage, var.group, var.env]
  tags_sorted = sort(distinct(local.tags))
  /* always add SSH, Tinc, Netdata, and Consul to allowed ports */
  open_tcp_ports  = concat(["22", "655", "8000", "8301"], var.open_tcp_ports)
  open_udp_ports  = concat(["655", "8301"], var.open_udp_ports)
}
/* RESOURCES ------------------------------------*/

resource "digitalocean_tag" "host" {
  name  = local.tags_sorted[count.index]
  count = length(local.tags_sorted)
}

/* Optional resource when vol_size is set */
resource "digitalocean_volume" "host" {
  name      = "data-${replace(var.name, ".", "-")}-${format("%02d", count.index+1)}-${replace(local.sufix, ".", "-")}"
  region    = var.region
  size      = var.data_vol_size
  count     = var.data_vol_size > 0 ? var.host_count : 0
  lifecycle {
    prevent_destroy = true
    /* We do this to avoid destrying a volume unnecesarily */
    ignore_changes = [ name ]
  }
}

resource "digitalocean_droplet" "host" {
  name   = "${var.name}-${format("%02d", count.index+1)}.${local.sufix}"

  image    = var.image
  region   = var.region
  size     = var.size
  count    = var.host_count
  ssh_keys = var.ssh_keys

  tags   = digitalocean_tag.host[*].id

  /* This can be optional, ugly as hell but it works */
  volume_ids = var.data_vol_size > 0 ? [digitalocean_volume.host[count.index].id] : null

  /* Ignore changes in attributes like image */
  lifecycle {
    ignore_changes = [ image ]
  }

  /* bootstraping access for later Ansible use */
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "${path.cwd}/ansible/bootstrap.yml"
      }

      hosts  = [self.ipv4_address]
      groups = [var.group]

      extra_vars = {
        hostname         = self.name
        ansible_ssh_user = var.ssh_user
        data_center      = local.dc
        stage            = local.stage
        env              = var.env
      }
    }
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
  name        = "${var.name}.${local.sufix}"
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

  groups = [var.group, local.dc]
  count  = var.host_count

  vars = {
    ansible_host = digitalocean_floating_ip.host[count.index].ip_address
    hostname     = digitalocean_droplet.host[count.index].name
    region       = digitalocean_droplet.host[count.index].region
    dns_entry    = "${digitalocean_droplet.host[count.index].name}.${var.domain}"
    dns_domain   = var.domain
    data_center  = local.dc
    stage        = local.stage
    env          = var.env
  }
}
