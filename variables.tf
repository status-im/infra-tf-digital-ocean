/* DNS ------------------------------------------*/

variable "cf_zone_id" {
  description = "ID of CloudFlare zone for host record."
  type        = string
  default     = "fd48f427e99bbe1b52105351260690d1"
}

variable "domain" {
  description = "DNS Domain to update"
  type        = string
  default     = "status.im"
}

/* SCALING --------------------------------------*/

variable "image" {
  description = "OS image used to create host."
  type        = string
  default     = "ubuntu-22-04-x64"
  /* cmd: doctl compute image list --public */
}

variable "type" {
  description = "Type of host to create."
  type        = string
  default     = "s-1vcpu-1gb"
  /* cmd: doctl compute size list */
}

variable "region" {
  description = "Region in which the host will be created."
  type        = string
  default     = "ams3"
  /* cmd: doctl compute region list */
}

variable "host_count" {
  description = "Number of hosts to start in this region."
  type        = number
  default     = 1
}

variable "provider_name" {
  description = "Short name of provider being used."
  type        = string
  default     = "do" /* Digital Ocean */
}

variable "data_vol_size" {
  description = "Size in GiB of an extra data volume to attach to the dropplet."
  type        = number
  default     = 0
}

/* GENERAL --------------------------------------*/

variable "name" {
  description = "Prefix of hostname before index."
  type        = string
  default     = "node"
}

variable "group" {
  description = "Name of Ansible group to add hosts to."
  type        = string
}

variable "env" {
  description = "Environment for these hosts, affects DNS entries."
  type        = string
}

variable "stage" {
  description = "Name of stage, like prod, dev, or staging."
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "User used to log in to instance"
  type        = string
  default     = "root"
}

variable "ssh_keys" {
  description = "Names of ssh public keys to add to created hosts"
  type        = list(string)
  default = [
    "20671731", # jakubgs
    "38154610", # alexis@status.im
    "39365941", # yakimant
  ]
  /* cmd: doctl compute ssh-key list */
}

/* FIREWALL -------------------------------------------*/

variable "open_tcp_ports" {
  description = "TCP port ranges to enable access from outside. Format: 'N-N'"
  type        = list(string)
  default     = []
}

variable "open_udp_ports" {
  description = "UDP port ranges to enable access from outside. Format: 'N-N'"
  type        = list(string)
  default     = []
}
