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
  region = var.regionlist[var.region]
  zone   = "${var.regionlist[var.region]}-${var.zone}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       			= "${var.prefix}-ssh"
  public_key 			= "${var.ssh-key}"
}

data "ibm_is_vpc" "selected" {
    name = "${var.logical_network}"
}

resource "ibm_is_bare_metal_server" "l1bm_automation_sample_bms" {
    profile      = "${var.profilelist[var.profile]}"
    name         = format("%s-bm", var.prefix)
    image        = data.ibm_is_image.this.id
    vpc          = data.ibm_is_vpc.selected.id
    zone         = "${var.regionlist[var.region]}-${var.zone}"
    #wait_before_deletion = var.wait_delete
    keys         = [ibm_is_ssh_key.sshkey.id]
    primary_network_interface {
        enable_infrastructure_nat = true
        subnet = {for id, v in data.ibm_is_vpc.selected.subnets : id => v.id if v.zone == "${var.regionlist[var.region]}-${var.zone}" }[0]
    interface_type          = "hipersocket"
    name                    = format("%s-bm-nic-1 ", var.prefix)
    security_groups         = [data.ibm_is_vpc.selected.default_security_group]

  } 

}

resource ibm_is_floating_ip l1bm_automation_sample_fip{
  name = format("%s-fip", var.prefix)
  zone = "${var.regionlist[var.region]}-${var.zone}"
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