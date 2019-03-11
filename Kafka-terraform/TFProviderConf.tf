variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

#Instance variables
variable "InstanceImageOCID" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "InstanceShape" {}

#Environment Variables
variable "compartment_ocid"{}

#Local Variables
variable "AD1" {default = "1"}
variable "AD2" {default = "2"}
data "oci_identity_availability_domains" "ADs" { compartment_id = "${var.tenancy_ocid}"}

#Provider
provider "oci" {
   tenancy_ocid = "${var.tenancy_ocid}"
   user_ocid = "${var.user_ocid}"
   fingerprint = "${var.fingerprint}"
   private_key_path = "${var.private_key_path}"
   region = "${var.region}"
   disable_auto_retries = "true"
}

#User Data variable
variable "user-data" {
  default = <<EOF
#!/bin/bash -x
echo '################### userdata begins #####################'
touch ~opc/userdata.`date +%s`.start

# echo '########## yum update ###############'
#sudo yum update -y
touch ~opc/userdata.`date +%s`.finish
echo '################### userdata ends #######################'
EOF
}