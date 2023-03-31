terraform {
   required_providers {
      ibm = {
         source = "IBM-Cloud/ibm"
         version = "1.51.0"
      }
    }
  }

 # make sure to target the correct region and zone 
 provider "ibm" {
  region = var.region
  zone   = "${var.region}-${var.zone}"
}

locals {
  # some reusable tags that identify the resources created by his sample
  tags = ["l1bm", "catalog", var.prefix]
}

resource "ibm_is_vpc" "l1bm_automation_sample_vpc" {
  name = format("%s-vpc", var.logical_network)
  tags = local.tags
}

# the security group
resource "ibm_is_security_group" "l1bm_automation_sample_security_group" {
  name = format("%s-security-group", var.prefix)
  vpc  = ibm_is_vpc.l1bm_automation_sample_vpc.id
  tags = local.tags
}

# rule that allows outbound traffic
resource "ibm_is_security_group_rule" "l1bm_automation_sample_outbound" {
  group     = ibm_is_security_group.l1bm_automation_sample_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# rule that allows inbound traffic
resource "ibm_is_security_group_rule" "l1bm_automation_sample_inbound" {
  group     = ibm_is_security_group.l1bm_automation_sample_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_subnet" "l1bm_automation_sample_subnet" {
  name                      = format("%s-subnet", var.prefix)
  vpc                       = ibm_is_vpc.l1bm_automation_sample_vpc.id
  zone                      = "${var.region}-${var.zone}"
  total_ipv4_address_count  = 16
}

data "ibm_is_ssh_key" "sshkey" {
  name       = format("%s-key", var.prefix)
  public_key = var.ssh-key
}


resource "ibm_is_bare_metal_server" "l1bm_automation_sample_bms" {

  profile                   = "${var.profile == "Small" ? "mz2d-metal-2x64" : "mz2d-metal-16x512"}"
  name                      = format("%s-bm", var.prefix)
  image                     = data.ibm_is_image.this.id
  zone                      = ibm_is_subnet.l1bm_automation_sample_subnet.zone
  keys                      = [ibm_is_ssh_key.sshkey.id]
  tags                      = local.tags
  primary_network_interface {
   enable_infrastructure_nat = true
    subnet                  = ibm_is_subnet.l1bm_automation_sample_subnet.id
    interface_type          = "hipersocket"
    name                    = format("%s-bm-nic-1 ", var.prefix)
    security_groups         = [ibm_is_security_group.l1bm_automation_sample_security_group.id]
  }
    vpc                     = ibm_is_vpc.l1bm_automation_sample_vpc.id
}

resource ibm_is_floating_ip l1bm_automation_sample_fip{
  name = format("%-fip", var.prefix)
  zone = ibm_is_subnet.l1bm_automation_sample_subnet.zone
}
resource ibm_is_bare_metal_server_network_interface_floating_ip l1bm_automation_sample_nic_fip {
  bare_metal_server = ibm_is_bare_metal_server.l1bm_automation_sample_bms.id
  network_interface = ibm_is_bare_metal_server.l1bm_automation_sample_bms.primary_network_interface.0.id
  floating_ip = ibm_is_floating_ip.l1bm_automation_sample_fip.id
}

data ibm_is_image this {
  name = "ibm-l1bm-rhel8-4-minimal-s390x-byol-1"
}

output "ip" {
  value = resource.ibm_is_floating_ip.l1bm_automation_sample_fip.address
  description = "The public IP address of the L1BM" 
}
