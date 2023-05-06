variable "tenancy_ocid" {}
variable "object_storage_namespace" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {
  default = "us-ashburn-1"
}
variable "availability_domain" {}
variable "ssh_public_key_path" {}

terraform {
  required_version = "= 1.4.6"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.119.0"
    }
  }
  cloud {
    organization = "tom-hummel"
    workspaces {
      name = "lab-tomhummel-com"
    }
  }
}

provider "oci" {
  auth                 = "APIKey"
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  region               = var.region
  disable_auto_retries = true
}

locals {
  project_name    = "lab"
  instance_shape  = "VM.Standard.A1.Flex"
  vcn_subnet_cidr = "10.89.0.0/30"
}

data "oci_core_images" "oel9" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_ocid = data.oci_core_images.oel9.images[0].id
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenancy.home_region_key]
  }
}

resource "oci_core_vcn" "lab" {
  cidr_block     = local.vcn_subnet_cidr
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name
  dns_label      = local.project_name
}

resource "oci_core_internet_gateway" "lab" {
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name
  vcn_id         = oci_core_vcn.lab.id
}

resource "oci_core_route_table" "lab" {
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.lab.id
  }

  vcn_id = oci_core_vcn.lab.id
}

data "external" "current_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

resource "oci_core_security_list" "lab" {
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    # Options are supported only for ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").
    protocol = 6
    # source   = "0.0.0.0/0"
    source = "${data.external.current_ip.result.ip}/32"

    tcp_options {
      max = 22
      min = 22
    }
  }

  vcn_id = oci_core_vcn.lab.id
}

resource "oci_core_subnet" "lab" {
  cidr_block                 = local.vcn_subnet_cidr
  compartment_id             = var.tenancy_ocid
  display_name               = local.project_name
  dns_label                  = "${local.project_name}sub"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.lab.id
  security_list_ids          = [oci_core_security_list.lab.id]
  vcn_id                     = oci_core_vcn.lab.id
}

locals {
  userdata = <<-EOT
    #!/bin/bash
    set -e

    # Add Caddy repository and install Caddy
    yum install -y yum-utils
    yum-config-manager --add-repo https://dl.caddyserver.com/rpm/stable/epel-7-aarch64.repo
    yum install -y caddy

    # Create a default "Hello World" HTML page
    cat > /var/www/html/index.html << EOF2
    <!DOCTYPE html>
    <html>
    <head>
        <title>Welcome to my lab</title>
    </head>
    <body>
        <h1>Welcome to my lab</h1>
        <p>This is the default fallback page.</p>
    </body>
    </html>
    EOF2

    # Set up the Caddyfile with a fallthrough "Hello World" HTML page
    cat > /etc/caddy/Caddyfile << EOF2
    {
    }

    # Specific site configurations can be added in the conf.d directory
    import /etc/caddy/conf.d/*

    # Fallback for unmatched *.subdomain.maindomain.com
    *.lab.tomhummel.com {
        root * /var/www/html
        file_server
        try_files {path} {path}/ /index.html
    }
    EOF2

    # Create the conf.d directory for specific site configurations
    mkdir -p /etc/caddy/conf.d

    # Enable and start Caddy as a systemd unit
    systemctl enable caddy
    systemctl start caddy
  EOT
}

resource "oci_core_instance" "lab" {
  availability_domain = var.availability_domain
  compartment_id      = var.tenancy_ocid

  create_vnic_details {
    assign_public_ip = true
    display_name     = local.project_name
    hostname_label   = local.project_name
    subnet_id        = oci_core_subnet.lab.id
  }

  display_name = local.project_name

  launch_options {
    boot_volume_type = "PARAVIRTUALIZED"
    network_type     = "PARAVIRTUALIZED"
  }

  # prevent the instance from destroying and recreating itself if the image ocid changes
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  shape = local.instance_shape

  source_details {
    boot_volume_size_in_gbs = 50
    source_type             = "image"
    source_id               = local.image_ocid
  }
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    userdata            = base64encode(local.userdata)
  }

  timeouts {
    create = "10m"
  }

  freeform_tags = {
    name = "star-lab-tomhummel-com"
  }
}

resource "oci_objectstorage_bucket" "lab" {
  compartment_id = var.tenancy_ocid
  name           = local.project_name
  namespace      = var.object_storage_namespace

  access_type           = "NoPublicAccess"
  object_events_enabled = false
  storage_tier          = "Standard"
  versioning            = "Disabled"
}

resource "oci_identity_dynamic_group" "lab" {
  compartment_id = var.tenancy_ocid
  description    = "all compute instances in tenancy"
  matching_rule  = "instance.compartment.id = '${var.tenancy_ocid}'"
  name           = local.project_name
}

resource "oci_identity_policy" "lab" {
  compartment_id = var.tenancy_ocid
  description    = local.project_name
  name           = local.project_name
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.lab.name} to read buckets in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.lab.name} to manage objects in tenancy where any {request.permission='OBJECT_CREATE', request.permission='OBJECT_INSPECT'}"
  ]
}