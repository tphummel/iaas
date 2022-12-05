terraform {
  required_version = "= 1.3.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
variable "oldgameswin_account_id" {}

# requires CLOUDFLARE_API_KEY env var
provider "cloudflare" {}

resource "cloudflare_zone" "oldgames_win" {
  account_id = var.oldgameswin_account_id
  zone       = "oldgames.win"
}

resource "cloudflare_record" "cname" {
  zone_id = cloudflare_zone.oldgames_win.id
  name    = "oldgames.win"
  value   = "video-game-quality.pages.dev"
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "txt" {
  zone_id = cloudflare_zone.oldgames_win.id
  name    = "oldgames.win"
  value   = "google-site-verification=syOULjauRiMwyK-1XcouVnXK6bISQoaNiL4MdTGvna0"
  type    = "TXT"
  ttl     = 1
  proxied = false
}

resource "cloudflare_pages_project" "oldgames_win" {
  account_id        = var.oldgameswin_account_id
  name              = "oldgameswin"
  production_branch = "main"
  build_config {
    build_command   = "hugo"
    destination_dir = "public"
    root_dir        = ""
  }
  source {
    type = "github"
    config {
      owner                         = "tphummel"
      repo_name                     = "video-game-quality"
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
        HUGO_VERSION = "0.87.0"
      }
      compatibility_date = "2022-08-15"
    }
    production {
      environment_variables = {
        HUGO_VERSION = "0.87.0"
      }
      compatibility_date = "2022-08-16"
    }
  }
}

resource "cloudflare_pages_domain" "oldgames_win" {
  account_id   = var.oldgameswin_account_id
  project_name = cloudflare_pages_project.oldgames_win.name
  domain       = "oldgames.win"
}