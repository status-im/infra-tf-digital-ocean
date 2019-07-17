/* DERIVED --------------------------------------*/
locals {
  stage       = "${terraform.workspace}"
  tokens      = "${split(".", local.stage)}"
  dc          = "${var.provider_name}-${var.region}"
  /* tags for the dropplet */
  tags        = ["${local.stage}", "${var.group}", "${var.env}"]
  tags_sorted = "${sort(distinct(local.tags))}"
  tags_count  = "${length(local.tags_sorted)}"
  /* always add SSH, Tinc, Netdata, and Consul to allowed ports */
  open_ports  = concat(["22", "655", "8000", "8301"], var.open_ports)
}
/* RESOURCES ------------------------------------*/

resource "digitalocean_tag" "host" {
  name  = "${element(local.tags_sorted, count.index)}"
  count = "${local.tags_count}"
}

/* Optional resource when vol_size is set */
resource "digitalocean_volume" "host" {
  name      = "data.${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"
  region    = "${var.region}"
  size      = "${var.vol_size}"
  count     = "${var.vol_size > 0 ? var.host_count : 0}"
  lifecycle {
    prevent_destroy = true
    /* We do this to avoid destrying a volume unnecesarily */
    ignore_changes = ["name"]
  }
}

resource "digitalocean_droplet" "host" {
  name   = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"

  image  = "${var.image}"
  region = "${var.region}"
  size   = "${var.size}"
  count  = "${var.host_count}"

  tags   = digitalocean_tag.host[*].id
  ssh_keys = "${var.ssh_keys}"

  /* This can be optional, ugly as hell but it works */
  volume_ids = var.vol_size > 0 ? [digitalocean_volume.host[count.index].id] : []

  /* Ignore changes in attributes like image */
  lifecycle {
    ignore_changes = ["image"]
  }

  /* bootstraping access for later Ansible use */
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "${path.cwd}/ansible/bootstrap.yml"
      }
      groups = ["${var.group}"]

      extra_vars = {
        hostname         = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"
        ansible_ssh_user = "${var.ssh_user}"
        data_center      = "${local.dc}"
        stage            = "${local.stage}"
        env              = "${var.env}"
      }
    }
  }
}

resource "digitalocean_floating_ip" "host" {
  droplet_id = "${element(digitalocean_droplet.host.*.id, count.index)}"
  region     = "${element(digitalocean_droplet.host.*.region, count.index)}"
  count      = "${var.host_count}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_firewall" "host" {
  name        = "${var.name}.${local.dc}.${var.env}.${local.stage}"
  droplet_ids = digitalocean_droplet.host[*].id
  dynamic "inbound_rule" {
    iterator = port
    for_each = local.open_ports
    content {
      protocol   = "tcp"
      port_range = port.value
    }
  }
}

resource "cloudflare_record" "host" {
  domain = "${var.domain}"
  count  = "${var.host_count}"
  name   = "${element(digitalocean_droplet.host.*.name, count.index)}"
  value  = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
  type   = "A"
  ttl    = 3600
}

/* combined dns entry for groups of hosts, example: nodes.do-ams3.thing.misc.statusim.net */
resource "cloudflare_record" "hosts" {
  domain = "${var.domain}"
  name   = "${var.name}s.${local.dc}.${var.env}.${local.stage}"
  value  = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
  count  = "${var.host_count}"
  type   = "A"
}

resource "ansible_host" "host" {
  inventory_hostname = "${element(digitalocean_droplet.host.*.name, count.index)}"
  groups = ["${var.group}", "${local.dc}"]
  count = "${var.host_count}"

  vars = {
    ansible_host = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
    hostname     = "${element(digitalocean_droplet.host.*.name, count.index)}"
    region       = "${element(digitalocean_droplet.host.*.region, count.index)}"
    dns_entry    = "${element(digitalocean_droplet.host.*.name, count.index)}.${var.domain}"
    dns_domain   = "${var.domain}"
    data_center  = "${local.dc}"
    stage        = "${local.stage}"
    env          = "${var.env}"
  }
}
