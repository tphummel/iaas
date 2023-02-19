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
      name = "cloudflare-reference"
    }
  }
}
variable "cloudflare_account_id" {}
variable "cloudflare_api_token" {}
variable "top_secret_value" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_workers_kv_namespace" "ref" {
  account_id = var.cloudflare_account_id
  title      = "CFREF"
}

resource "cloudflare_workers_kv" "example" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.ref.id
  key          = "test-key"
  value        = "test value"
}

# Sets the script with the name "script_1"
resource "cloudflare_worker_script" "my_script" {
  account_id = var.cloudflare_account_id
  name       = "script_1"
  content    = file("script.js")

  kv_namespace_binding {
    name         = "KV_CF_REF"
    namespace_id = cloudflare_workers_kv_namespace.ref.id
  }

  plain_text_binding {
    name = "MY_EXAMPLE_PLAIN_TEXT"
    text = "foobar"
  }

  secret_text_binding {
    name = "MY_EXAMPLE_SECRET_TEXT"
    text = var.top_secret_value
  }
}

# resource "cloudflare_worker_route" "ref" {
#   zone_id     = "416e9ed3614707fb2e3ae8af726be325"
#   pattern     = "script_1.tphummel.workers.dev/*"
#   script_name = cloudflare_worker_script.my_script.name
# }
