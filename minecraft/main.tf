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
  required_version = "= 1.3.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.103.0"
    }
  }
  cloud {
    organization = "tom-hummel"
    workspaces {
      name = "minecraft"
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
  project_name    = "minecraft"
  instance_shape  = "VM.Standard.A1.Flex"
  image_ocid      = "ocid1.image.oc1.iad.aaaaaaaabr2p2s6fnh5kf4u77y7se2kmaieuzjhqfmjwquw3csgq32i6kx5a"
  vcn_subnet_cidr = "10.88.0.0/30"
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

resource "oci_core_vcn" "mc" {
  cidr_block     = local.vcn_subnet_cidr
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name
  dns_label      = local.project_name
}

resource "oci_core_internet_gateway" "mc" {
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name
  vcn_id         = oci_core_vcn.mc.id
}

resource "oci_core_route_table" "mc" {
  compartment_id = var.tenancy_ocid
  display_name   = local.project_name

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.mc.id
  }

  vcn_id = oci_core_vcn.mc.id
}

data "external" "current_ip" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

resource "oci_core_security_list" "mc" {
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

  ingress_security_rules {
    # Options are supported only for ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").
    protocol = 6
    source   = "0.0.0.0/0"

    tcp_options {
      max = 25565
      min = 25565
    }
  }

  ingress_security_rules {
    protocol = 17 // udp
    source   = "0.0.0.0/0"

    udp_options {
      max = 25565
      min = 25565
    }
  }

  ingress_security_rules {
    protocol = 1 // icmp
    source   = "0.0.0.0/0"
  }

  vcn_id = oci_core_vcn.mc.id
}

resource "oci_core_subnet" "mc" {
  cidr_block                 = local.vcn_subnet_cidr
  compartment_id             = var.tenancy_ocid
  display_name               = local.project_name
  dns_label                  = "${local.project_name}sub"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.mc.id
  security_list_ids          = [oci_core_security_list.mc.id]
  vcn_id                     = oci_core_vcn.mc.id
}

resource "oci_core_instance" "mc" {
  availability_domain = var.availability_domain
  compartment_id      = var.tenancy_ocid

  create_vnic_details {
    assign_public_ip = true
    display_name     = local.project_name
    hostname_label   = local.project_name
    subnet_id        = oci_core_subnet.mc.id
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
    user_data           = <<-EOF
#!/bin/bash
# install netcat
# install htop
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo rpm --import https://yum.corretto.aws/corretto.key
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
sudo dnf -y install java-17-amazon-corretto-devel
sudo wget https://api.papermc.io/v2/projects/paper/versions/1.19.3/builds/381/downloads/paper-1.19.3-381.jar > /home/opc/
sudo chown opc:opc /home/opc/paper-1.19.3-381.jar
echo eula=true > eula.txt
cat <<MCUNIT | sudo tee /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server

[Service]
WorkingDirectory=/home/opc/
ExecStart=/usr/bin/java -Xms4G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper-1.19.3-381.jar --nogui
User=opc
Group=opc
Type=simple
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
MCUNIT

sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service

EOF
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_objectstorage_bucket" "mc" {
  compartment_id = var.tenancy_ocid
  name           = local.project_name
  namespace      = var.object_storage_namespace

  access_type           = "NoPublicAccess"
  object_events_enabled = false
  storage_tier          = "Standard"
  versioning            = "Disabled"
}

resource "oci_identity_dynamic_group" "mc" {
  compartment_id = var.tenancy_ocid
  description    = "all compute instances in tenancy"
  matching_rule  = "instance.compartment.id = '${var.tenancy_ocid}'"
  name           = local.project_name
}

resource "oci_identity_policy" "mc" {
  compartment_id = var.tenancy_ocid
  description    = local.project_name
  name           = local.project_name
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.mc.name} to read buckets in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.mc.name} to manage objects in tenancy where any {request.permission='OBJECT_CREATE', request.permission='OBJECT_INSPECT'}"
  ]
}