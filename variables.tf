/* SCALING --------------------------------------*/

variable image {
  description = "OS image used to create host."
  # cmd: doctl compute image list --public
  default     = "ubuntu-18-04-x64"
}

variable size {
  description = "Type of host to create."
  # cmd: doctl compute size list
  default     = "s-1vcpu-1gb"
}

variable region {
  description = "Region in which the host will be created."
  # cmd: doctl compute region list
  default     = "ams3"
}

variable host_count {
  description = "Number of hosts to start in this region."
}

variable provider_name {
  description = "Short name of provider being used."
  # Digital Ocean
  default     = "do"
}

variable vol_size {
  description = "Size in GiB of an extra Volume to attach to the dropplet."
  default     = 0
}

/* GENERAL --------------------------------------*/

variable name {
  description = "Prefix of hostname before index."
  default     = "node"
}

variable group {
  description = "Name of Ansible group to add hosts to."
}

variable env {
  description = "Environment for these hosts, affects DNS entries."
}

variable domain {
  description = "DNS Domain to update"
}

variable ssh_user {
  description = "User used to log in to instance"
  default     = "root"
}

variable ssh_keys {
  description = "Names of ssh public keys to add to created hosts"
  type        = "list"
  # cmd: doctl compute ssh-key list
  default     = ["16822693", "18813432", "18813461", "19525749", "20671731", "20686611"]
}

/* FIREWALL -------------------------------------------*/

variable open_ports {
  description = "Port ranges to enable access from outside. Format: 'N-N'"
  type        = "list"
  default     = []
}
