terraform {
  required_version = "= 1.3.6"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "4.119.0"
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

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_region" {
  default = "us-ashburn-1"
}

provider "oci" {
  auth                 = "APIKey"
  tenancy_ocid         = var.oci_tenancy_ocid
  user_ocid            = var.oci_user_ocid
  fingerprint          = var.oci_fingerprint
  private_key_path     = var.oci_private_key_path
  region               = var.oci_region
  disable_auto_retries = true
}

resource "cloudflare_zone" "tomhummel_com" {
  account_id = var.tomhummel_com_account_id
  zone       = "tomhummel.com"
}

resource "cloudflare_pages_project" "apex" {
  account_id        = var.tomhummel_com_account_id
  name              = "tomhummel-com"
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
      repo_name                     = "blog"
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
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.87.0"
      }
    }
    production {
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.87.0"
      }
    }
  }
}

resource "cloudflare_pages_domain" "apex" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.apex.name
  domain       = "tomhummel.com"
}

resource "cloudflare_record" "apex" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.apex.domain
  value   = cloudflare_pages_project.apex.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_pages_domain" "www" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.apex.name
  domain       = "www.tomhummel.com"
}

resource "cloudflare_record" "www" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.www.domain
  value   = cloudflare_pages_project.apex.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_pages_project" "data" {
  account_id        = var.tomhummel_com_account_id
  name              = "data-tomhummel-com"
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
      repo_name                     = "data.tomhummel.com"
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
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.96.0"
      }
    }
    production {
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.96.0"
      }
    }
  }
}

resource "cloudflare_pages_domain" "data" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.data.name
  domain       = "data.tomhummel.com"
}

resource "cloudflare_record" "data" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.data.domain
  value   = cloudflare_pages_project.data.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

variable "wordle_honeycomb_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_r2_access_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_r2_secret_key" {
  type      = string
  sensitive = true
}

# https://developers.cloudflare.com/r2/examples/terraform/
provider "aws" {
  access_key = var.cloudflare_r2_access_key
  secret_key = var.cloudflare_r2_secret_key
  skip_credentials_validation = true
  skip_region_validation = true
  skip_requesting_account_id = true
  endpoints {
    s3 = "https://${var.tomhummel_com_account_id}.r2.cloudflarestorage.com"
  }
}

resource "aws_s3_bucket" "wordle_contest_entries_preview" {
  bucket = "wordle-contest-entries-preview"
}

resource "aws_s3_bucket" "wordle_contest_entries" {
  bucket = "wordle-contest-entries"
}

resource "cloudflare_pages_project" "wordle" {
  account_id        = var.tomhummel_com_account_id
  name              = "wordle"
  production_branch = "main"
  build_config {
    build_command   = "git submodule update --init --recursive && hugo"
    destination_dir = "public"
    root_dir        = "/"
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
      fail_open = true
      environment_variables = {
        HUGO_VERSION      = "0.87.0"
        HONEYCOMB_DATASET = "cloudflare-wordle-tomhummel-com-preview"
        HONEYCOMB_KEY     = var.wordle_honeycomb_key
      }
      r2_buckets = {
        "WORDLE_CONTEST_ENTRIES" = aws_s3_bucket.wordle_contest_entries_preview.id
      }
      compatibility_date = "2022-08-15"
    }
    production {
      fail_open = true
      environment_variables = {
        HUGO_VERSION      = "0.87.0"
        HONEYCOMB_DATASET = "cloudflare-wordle-tomhummel-com"
        HONEYCOMB_KEY     = var.wordle_honeycomb_key
      }
      r2_buckets = {
        "WORDLE_CONTEST_ENTRIES" = aws_s3_bucket.wordle_contest_entries.id
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
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.101.0"
      }
      compatibility_date = "2022-10-30"
    }
    production {
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.101.0"
      }
      r2_buckets = {
        "R2" = "movies-tomhummel-com-images"
      }
      compatibility_date = "2022-10-30"
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

resource "cloudflare_pages_project" "mlb" {
  account_id        = var.tomhummel_com_account_id
  name              = "mlb-tomhummel-com"
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
      repo_name                     = "mlb.tomhummel.com"
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
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.99.1"
      }
      compatibility_date = "2022-08-15"
    }
    production {
      fail_open = true
      environment_variables = {
        HUGO_VERSION = "0.99.1"
      }
      compatibility_date = "2022-08-16"
    }
  }
}

resource "cloudflare_pages_domain" "mlb" {
  account_id   = var.tomhummel_com_account_id
  project_name = cloudflare_pages_project.mlb.name
  domain       = "mlb.tomhummel.com"
}

resource "cloudflare_record" "mlb" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = cloudflare_pages_domain.mlb.domain
  value   = cloudflare_pages_project.mlb.subdomain
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

data "oci_core_instances" "lab_servers" {
  compartment_id = var.oci_tenancy_ocid
  display_name = "lab"
  state = "RUNNING"
}

data "oci_core_vnic_attachments" "instance_vnic_attachments" {
  compartment_id = var.oci_tenancy_ocid
  instance_id    = data.oci_core_instances.lab_servers.instances[0]["id"]
}

data "oci_core_vnic" "instance_vnic" {
  vnic_id = data.oci_core_vnic_attachments.instance_vnic_attachments.vnic_attachments[0]["vnic_id"]
}

resource "cloudflare_record" "star_lab_tomhummel_com" {
  name    = "*.lab"
  value   = data.oci_core_vnic.instance_vnic.public_ip_address
  type    = "A"
  proxied = false
  zone_id = cloudflare_zone.tomhummel_com.id
}