# Description

This is a helper module used by Status internal repos like:

* https://github.com/status-im/infra-hq
* https://github.com/status-im/infra-misc
* https://github.com/status-im/infra-eth-cluster
* https://github.com/status-im/infra-swarm

# Usage

Simply import the modue using the `source` directive:
```terraform
module "digital-ocean" {
  source = "github.com/status-im/infra-tf-digital-ocean"
}
```

For more details see:
https://www.terraform.io/docs/modules/sources.html#github
