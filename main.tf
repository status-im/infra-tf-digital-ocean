/* DERIVED --------------------------------------*/
locals {
  stage  = "${terraform.workspace}"
  tokens = "${split(".", local.stage)}"
  dc     = "${var.provider}-${var.region}"
  /* tags for the dropplet */
  tags = ["${local.stage}", "${var.group}", "${var.env}"]
  tags_sorted = "${sort(distinct(local.tags))}"
  tags_count = "${length(local.tags_sorted)}"
  /* always add SSH, Tinc, Netdata, and Consul to allowed ports */
  open_ports = [
    "22", "655", "8000", "8301",
    "${var.open_ports}"
  ]
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
  count     = "${var.vol_size > 0 ? var.count : 0}"
  lifecycle = { prevent_destroy = true }
}

resource "digitalocean_droplet" "host" {
  name   = "${var.name}-${format("%02d", count.index+1)}.${local.dc}.${var.env}.${local.stage}"

  image  = "${var.image}"
  region = "${var.region}"
  size   = "${var.size}"
  count  = "${var.count}"

  tags   = [ "${digitalocean_tag.host.*.id}"]
  ssh_keys = "${var.ssh_keys}"

  /* This can be optional, ugly as hell but it works */
  volume_ids = [
    "${compact(list(var.vol_size > 0 ? element(concat(digitalocean_volume.host.*.id, list("")), count.index) : ""))}"
  ]

  /* Ignore changes in attributes like image */
  lifecycle {
    ignore_changes = ["image"]
  }

  /* bootstraping access for later Ansible use */
  provisioner "ansible" {
    plays {
      playbook = {
        file_path = "${path.cwd}/ansible/bootstrap.yml"
      }
      groups   = ["${var.group}"]
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
  count      = "${var.count}"
  lifecycle  = { prevent_destroy = true }
}

/**
 * This is a hack to generate a list of maps from a list
 * https://stackoverflow.com/questions/47273733/how-do-i-build-a-list-of-maps-in-terraform
 **/
resource "null_resource" "open_ports" {
  count = "${length(local.open_ports)}"
  triggers {
    protocol   = "tcp"
    port_range = "${element(local.open_ports, count.index)}"
  }
}

resource "digitalocean_firewall" "host" {
  name        = "${var.name}.${local.dc}.${var.env}.${local.stage}"
  droplet_ids = ["${digitalocean_droplet.host.*.id}"]
  inbound_rule = ["${null_resource.open_ports.*.triggers}"]
}

resource "cloudflare_record" "host" {
  domain = "${var.domain}"
  count  = "${var.count}"
  name   = "${element(digitalocean_droplet.host.*.name, count.index)}"
  value  = "${element(digitalocean_floating_ip.host.*.ip_address, count.index)}"
  type   = "A"
  ttl    = 3600
}

resource "ansible_host" "host" {
  inventory_hostname = "${element(digitalocean_droplet.host.*.name, count.index)}"
  groups = ["${var.group}", "${local.dc}"]
  count = "${var.count}"
  vars {
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
