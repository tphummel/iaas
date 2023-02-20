terraform {
  required_version = "= 1.3.9"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  cloud {
    organization = "tom-hummel"
    workspaces {
      name = "cloudflare-reference_hello-worker"
    }
  }
}
variable "cloudflare_account_id" {}
variable "cloudflare_api_token" {}
variable "top_secret_value" {}

locals {
  kv_title = "CF_HELLO"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_workers_kv_namespace" "hello" {
  account_id = var.cloudflare_account_id
  title      = local.kv_title
}

resource "cloudflare_workers_kv" "hello" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.hello.id
  key          = "hello"
  value        = "hi there!"
}

resource "cloudflare_workers_kv" "debug_output" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.hello.id
  key          = "debug_output_enabled"
  value        = "true"
}

# resource "cloudflare_r2_bucket" "hello" {
#   name = "hello"
#   region = "us-east-1"
# }

resource "cloudflare_worker_script" "hello" {
  account_id = var.cloudflare_account_id
  name       = "hello"
  content    = file("hello.js")

  kv_namespace_binding {
    name         = "KV_${local.kv_title}"
    namespace_id = cloudflare_workers_kv_namespace.hello.id
  }

  plain_text_binding {
    name = "MY_EXAMPLE_PLAIN_TEXT"
    text = "foobar"
  }

  secret_text_binding {
    name = "MY_EXAMPLE_SECRET_TEXT"
    text = var.top_secret_value
  }

  // as of 2023-02-20, the R2 bucket must be created in the web console prior to running terraform
  r2_bucket_binding {
    name        = "HELLO_BUCKET"
    bucket_name = "hello"
  }
}


