/* DNS ------------------------------------------*/

variable cf_zone_id {
  description = "ID of CloudFlare zone for host record."
  type        = string
  /* We default to: statusim.net */
  default     = "14660d10344c9898521c4ba49789f563"
}

/* SCALING --------------------------------------*/

variable image {
  description = "OS image used to create host."
  type        = string
  # cmd: doctl compute image list --public
  default     = "ubuntu-20-04-x64"
}

variable size {
  description = "Type of host to create."
  type        = string
  # cmd: doctl compute size list
  default     = "s-1vcpu-1gb"
}

variable region {
  description = "Region in which the host will be created."
  type        = string
  # cmd: doctl compute region list
  default     = "ams3"
}

variable host_count {
  description = "Number of hosts to start in this region."
  type        = number
  default     = 1
}

variable provider_name {
  description = "Short name of provider being used."
  type        = string
  # Digital Ocean
  default     = "do"
}

variable data_vol_size {
  description = "Size in GiB of an extra data volume to attach to the dropplet."
  type        = number
  default     = 0
}

/* GENERAL --------------------------------------*/

variable name {
  description = "Prefix of hostname before index."
  type        = string
  default     = "node"
}

variable group {
  description = "Name of Ansible group to add hosts to."
  type        = string
}

variable env {
  description = "Environment for these hosts, affects DNS entries."
  type        = string
}

variable "stage" {
  description = "Name of stage, like prod, dev, or staging."
  type        = string
  default     = ""
}

variable domain {
  description = "DNS Domain to update"
  type        = string
}

variable ssh_user {
  description = "User used to log in to instance"
  type        = string
  default     = "root"
}

variable ssh_keys {
  description = "Names of ssh public keys to add to created hosts"
  type        = list(string)
  # cmd: doctl compute ssh-key list
  default     = ["16822693", "18813432", "18813461", "19525749", "20671731", "20686611"]
}

/* FIREWALL -------------------------------------------*/

variable open_tcp_ports {
  description = "TCP port ranges to enable access from outside. Format: 'N-N'"
  type        = list(string)
  default     = []
}

variable open_udp_ports {
  description = "UDP port ranges to enable access from outside. Format: 'N-N'"
  type        = list(string)
  default     = []
}
