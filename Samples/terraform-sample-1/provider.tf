variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

provider "oci" {
   tenancy_ocid = "${var.tenancy_ocid}"
   user_ocid = "${var.user_ocid}"
   fingerprint = "${var.fingerprint}"
   private_key_path = "${var.private_key_path}"
   region = "${var.region}"
}

data "oci_identity_availability_domains" "ADs" { compartment_id = "${var.tenancy_ocid}"}
output "ADprint" {value = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"}