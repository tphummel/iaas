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
      name = "cloudflare-iam"
    }
  }
}
variable "cloudflare_account_id" {
  type = string
  sensitive = true
}
variable "cloudflare_api_key" {
  type = string
  sensitive = true
}
variable "cloudflare_email" {
  type = string
}
variable "cloudflare_member_id" {
  type = string
}

provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email = var.cloudflare_email
}

data "cloudflare_api_token_permission_groups" "all" {}

data "cloudflare_zone" "old_games_win" {
  name = "oldgames.win"
}

resource "cloudflare_api_token" "old_games_win" {
  name = "iaas/cf_iam - oldgames.win"

  # account
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.account["Account Analytics Read"],
      data.cloudflare_api_token_permission_groups.all.account["Account Settings Read"],
      data.cloudflare_api_token_permission_groups.all.account["D1 Write"],
      data.cloudflare_api_token_permission_groups.all.account["Logs Write"],
      data.cloudflare_api_token_permission_groups.all.account["Pages Write"],
      data.cloudflare_api_token_permission_groups.all.account["Workers KV Storage Write"],
      data.cloudflare_api_token_permission_groups.all.account["Workers R2 Storage Write"],
      data.cloudflare_api_token_permission_groups.all.account["Workers Scripts Write"],
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }

  # user
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.user["Memberships Read"],
      data.cloudflare_api_token_permission_groups.all.user["User Details Read"],
    ]
    resources = {
      "com.cloudflare.api.user.${var.cloudflare_member_id}" = "*"
    }
  }

  # zone
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Logs Write"],
      data.cloudflare_api_token_permission_groups.all.zone["SSL and Certificates Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Workers Routes Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Settings Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Transform Rules Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Versioning Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone WAF Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${data.cloudflare_zone.old_games_win.id}" = "*"
    }
  }
}

data "cloudflare_zone" "tomhummel_com" {
  name = "tomhummel.com"
}

resource "cloudflare_api_token" "tomhummel_com" {
  name = "iaas/cf_iam - tomhummel.com"

  # account
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.account["Account Analytics Read"],
      data.cloudflare_api_token_permission_groups.all.account["Account Settings Read"],
      data.cloudflare_api_token_permission_groups.all.account["D1 Write"],
      data.cloudflare_api_token_permission_groups.all.account["Logs Write"],
      data.cloudflare_api_token_permission_groups.all.account["Pages Write"],
      data.cloudflare_api_token_permission_groups.all.account["Workers KV Storage Write"],
      data.cloudflare_api_token_permission_groups.all.account["Workers Scripts Write"],
      data.cloudflare_api_token_permission_groups.all.account["Email Routing Addresses Write"],
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }

  # user
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.user["Memberships Read"],
      data.cloudflare_api_token_permission_groups.all.user["User Details Read"],
    ]
    resources = {
      "com.cloudflare.api.user.${var.cloudflare_member_id}" = "*"
    }
  }

  # zone
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Logs Write"],
      data.cloudflare_api_token_permission_groups.all.zone["SSL and Certificates Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Workers Routes Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Settings Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Transform Rules Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone Versioning Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Zone WAF Write"],
      data.cloudflare_api_token_permission_groups.all.zone["Email Routing Rules Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${data.cloudflare_zone.tomhummel_com.id}" = "*"
    }
  }
}

resource "cloudflare_api_token" "tomhummel_com_r2" {
  name = "iaas/cf_iam - tomhummel.com - r2 only"

  # account
  policy {
    effect = "allow"
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.account["Workers R2 Storage Write"],
    ]
    resources = {
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    }
  }
}

# output "all_permission_groups" {
#   value = data.cloudflare_api_token_permission_groups.all
# }