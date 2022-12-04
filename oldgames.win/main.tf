terraform {
  required_version = "= 1.3.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

variable "oldgameswin_cloudflare_api_token" {}
variable "oldgameswin_account_id" {}
variable "oldgameswin_zone_id" {}


provider "cloudflare" {
  api_token = var.oldgameswin_cloudflare_api_token
}

resource "cloudflare_pages_project" "oldgames_win" {
  account_id        = var.oldgameswin_account_id
  name              = "oldgameswin"
  production_branch = "main"
  build_config {
    build_command       = "hugo"
    destination_dir     = "/public"
    root_dir            = "/"
  }
  source {
    type = "github"
    config {
      owner                         = "tphummel"
      repo_name                     = "oldgames.win"
      production_branch             = "main"
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      preview_deployment_setting    = "all"
    }
  }
  deployment_configs {
    preview {
      environment_variables = {
        HUGO_VERSION = "0.87.0"
      }
      compatibility_date  = "2022-08-15"
    }
    production {
      environment_variables = {
        HUGO_VERSION = "0.87.0"
      }
      compatibility_date  = "2022-08-16"
    }
  }
}

resource "cloudflare_pages_domain" "oldgames_win" {
  account_id = var.oldgameswin_account_id
  project_name = cloudflare_pages_project.oldgames_win.name
  domain       = "oldgames.win"
}