
terraform {
  required_version = "> 1.3.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "= 2.42.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 4.26.0"
    }
    ansible = {
      source  = "nbering/ansible"
      version = "= 1.0.4"
    }
  }
}
