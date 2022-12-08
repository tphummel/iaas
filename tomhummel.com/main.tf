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

resource "cloudflare_pages_project" "wordle" {
  account_id        = var.tomhummel_com_account_id
  name              = "wordle"
  production_branch = "main"
  build_config {
    build_command   = "git submodule update --init --recursive && hugo"
    destination_dir = "public"
    root_dir        = ""
  }
  source {
    type = "github"
    config {
      owner                         = "tphummel"
      repo_name                     = "wordle-static"
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

resource "cloudflare_pages_domain" "wordle" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.wordle.name
  domain       = "wordle.tomhummel.com"
}

resource "cloudflare_record" "wordle" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.wordle.domain
  value   = cloudflare_pages_project.wordle.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_pages_project" "movies" {
  account_id        = var.tomhummel_com_account_id
  name              = "movies"
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
      repo_name                     = "movies"
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
        HUGO_VERSION = "0.101.0"
      }
      compatibility_date = "2022-08-15"
    }
    production {
      environment_variables = {
        HUGO_VERSION = "0.101.0"
      }
      r2_buckets = {
        "R2" = "movies-tomhummel-com-images"
      }
      compatibility_date = "2022-08-16"
    }
  }
}

resource "cloudflare_pages_domain" "movies" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.movies.name
  domain       = "movies.tomhummel.com"
}

resource "cloudflare_record" "movies" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.movies.domain
  value   = cloudflare_pages_project.movies.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}