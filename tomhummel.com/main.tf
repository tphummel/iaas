terraform {
  required_version = "= 1.3.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  cloud {
    organization = "tom-hummel"
    workspaces {
      name = "tomhummel-com"
    }
  }
}

variable "tomhummel_com_account_id" {
  type = string
}

# requires CLOUDFLARE_API_TOKEN env var
provider "cloudflare" {}

resource "cloudflare_zone" "tomhummel_com" {
  account_id = var.tomhummel_com_account_id
  zone       = "tomhummel.com"
}

resource "cloudflare_record" "cname-proxied" {
  for_each = {
    "data"          = "data.tomhummel.com.s3-website-us-east-1.amazonaws.com"
    "tomhummel.com" = "tomhummel.com.s3-website-us-east-1.amazonaws.com"
    "www"           = "www.tomhummel.com.s3-website-us-east-1.amazonaws.com"
  }
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = each.key
  value   = each.value
  type    = "CNAME"
  ttl     = 1
  proxied = true
}