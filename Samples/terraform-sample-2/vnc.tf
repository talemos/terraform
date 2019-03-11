variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

#network variable
variable "compartment_ocid"{}

provider "oci" {
   tenancy_ocid = "${var.tenancy_ocid}"
   user_ocid = "${var.user_ocid}"
   fingerprint = "${var.fingerprint}"
   private_key_path = "${var.private_key_path}"
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
