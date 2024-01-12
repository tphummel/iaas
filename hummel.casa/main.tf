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

resource "cloudflare_pages_project" "strider_1977" {
  account_id        = var.hummel_casa_account_id
  name              = "strider-1977"
  production_branch = "main"
  build_config {
    build_command   = "hugo"
    destination_dir = "public"
    root_dir        = "/"
  }
  source {
    type = "github"
    config {
      owner                         = "tphummel"
      repo_name                     = "strider-1977"
      production_branch             = "main"
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      preview_deployment_setting    = "all"
      preview_branch_includes       = ["*"]
    }
  }
  deployment_configs {
    preview {
      environment_variables = {
        HUGO_VERSION = "0.116.1"
      }
      compatibility_date = "2022-08-15"
    }
    production {
      environment_variables = {
        HUGO_VERSION = "0.116.1"
      }
      compatibility_date = "2022-08-16"
    }
  }
}

resource "cloudflare_pages_domain" "strider_1977" {
  account_id   = var.hummel_casa_account_id
  project_name = cloudflare_pages_project.strider_1977.name
  domain       = "strider-1977.hummel.casa"
}

resource "cloudflare_record" "strider_1977" {
  zone_id = cloudflare_zone.hummel_casa.id
  name    = cloudflare_pages_domain.strider_1977.domain
  value   = cloudflare_pages_project.strider_1977.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}