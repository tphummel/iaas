terraform {
  required_version = "= 1.5.7"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  cloud {
    organization = "tom-hummel"
    workspaces {
      name = "hummel-casa"
    }
  }
}

variable "hummel_casa_account_id" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# wasn't created here, imported
# i'm not sure what permissions are needed to create a zone. 
# also the zone gets created automatically when you add a domain to cloudflare
# Error: error creating zone "hummel.casa": Requires permission "com.cloudflare.api.account.zone.create" to create zones for the selected account
resource "cloudflare_zone" "hummel_casa" {
  account_id = var.hummel_casa_account_id
  zone       = "hummel.casa"
}