variable "region" {}

#network variable
variable "compartment_ocid"{}

provider "oci" {
   region = "${var.region}"
   disable_auto_retries = "true"
}

#netework resource
resource "oci_core_virtual_network" "VNC-1" {
   cidr_block = "10.1.0.0/16"
   compartment_id = "${var.compartment_ocid}"
   display_name = "VNC-2"
}

output "OCI-VCN-OCID" {
  value = "${oci_core_virtual_network.VNC-1.id}"
}
