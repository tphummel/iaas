resource "cloudflare_email_routing_settings" "hummel_casa" {
  zone_id = cloudflare_zone.hummel_casa.id
  enabled = "true"
}

resource "cloudflare_email_routing_address" "tohu_hey_com" {
  account_id = var.hummel_casa_account_id
  email      = "tohu@hey.com"
}

resource "cloudflare_email_routing_catch_all" "star_hummel_casa" {
  zone_id = cloudflare_zone.hummel_casa.id
  name    = "star_hummel_casa"
  enabled = true

  matcher {
    type = "all"
  }

  action {
    type  = "forward"
    value = [cloudflare_email_routing_address.tohu_hey_com.email]
  }
}