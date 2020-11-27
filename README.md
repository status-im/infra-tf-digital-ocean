# Description

This is a helper module used by Status internal repos like: [infra-hq](https://github.com/status-im/infra-hq), [infra-misc](https://github.com/status-im/infra-misc), [infra-eth-cluster](https://github.com/status-im/infra-eth-cluster), or [infra-swarm](https://github.com/status-im/infra-swarm).

# Usage

Simply import the modue using the `source` directive:
```hcl
module "digital-ocean" {
  source = "github.com/status-im/infra-tf-digital-ocean"
}
```

[More details.](https://www.terraform.io/docs/modules/sources.html#github)

# Variables

* __Scaling__
  * `host_count` - Number of hosts to start in this region.
  * `image` - OS image used to create host. (default: `ubuntu-18-04-x64`)
  * `size` - Type of host to create. (default: `s-1vcpu-1gb`)
  * `region` - Region in which the host will be created. (default: `ams3`)
  * `data_vol_size` - Size in GiB of an extra data volume to attach to the dropplet. (default: 0)
* __General__
  * `name` - Prefix of hostname before index. (default: `node`)
  * `group` - Name of Ansible group to add hosts to.
  * `env` - Environment for these hosts, affects DNS entries.
  * `stage` - Name of stage, like `prod`, `dev`, or `staging`.
  * `domain` - DNS Domain to update.
* __Security__
  * `ssh_user` - User used to log in to instance (default: `root`)
  * `ssh_keys` - Names of ssh public keys to add to created hosts.
  * `open_tcp_ports` - TCP port ranges to enable access from outside. Format: `N-N` (default: `[]`)
  * `open_udp_ports` - UDP port ranges to enable access from outside. Format: `N-N` (default: `[]`)
