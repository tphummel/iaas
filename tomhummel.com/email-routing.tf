resource "cloudflare_email_routing_settings" "tomhummel_com" {
  zone_id = cloudflare_zone.tomhummel_com.id
  enabled = "true"
}

resource "cloudflare_email_routing_address" "tohu_hey_com" {
  account_id = var.tomhummel_com_account_id
  email      = "tohu@hey.com"
}

resource "cloudflare_email_routing_catch_all" "star_tomhummel_com" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = "star_tomhummel_com"
  enabled = true

  matcher {
    type = "all"
  }

  action {
    type  = "forward"
    value = [cloudflare_email_routing_address.tohu_hey_com.email]
  }
}

resource "cloudflare_email_routing_rule" "me_tomhummel_com" {
  zone_id = cloudflare_zone.tomhummel_com.id
  name    = "me_tomhummel_com"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "me@tomhummel.com"
  }

  action {
    type  = "forward"
    value = [cloudflare_email_routing_address.tohu_hey_com.email]
  }
}