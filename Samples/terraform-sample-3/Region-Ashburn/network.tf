variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

#Environment Variables
variable "compartment_ocid"{}

#Local Variables
variable "AD" {default = "1"}
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

#Netework resource
resource "oci_core_vcn" "VNC-1" {
   cidr_block = "10.1.0.0/16"
   compartment_id = "${var.compartment_ocid}"
   display_name = "VNC-1"
   dns_label ="vnc1"
}

#Subnet resource
resource "oci_core_subnet" "SubNet-1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  cidr_block = "10.1.10.0/24"
  display_name = "SubNet-1"
  security_list_ids   = ["${oci_core_security_list.SL-1.id}"]
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.VNC-1.id}"
  route_table_id = "${oci_core_route_table.RT-1.id}"
  dns_label="subnet1"
}

#Internet Gateway
resource "oci_core_internet_gateway" "IG-1" {
  compartment_id = "${var.compartment_ocid}"
  display_name = "IG-1"
  vcn_id = "${oci_core_vcn.VNC-1.id}"
}

#Route Table
resource "oci_core_route_table" "RT-1" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.VNC-1.id}"
  display_name = "RT-1"
  route_rules {
    destination = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.IG-1.id}"
  }
}

#Security List
resource "oci_core_security_list" "SL-1" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "SL-1"
  vcn_id         = "${oci_core_vcn.VNC-1.id}"

  egress_security_rules = [{
    protocol    = "all"
    destination = "0.0.0.0/0"
  },
  ]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  },
    {
      icmp_options {
        "type" = 0
      }

      protocol = 1
      source   = "0.0.0.0/0"
    },
    {
      icmp_options {
        "type" = 3
        "code" = 4
      }

      protocol = 1
      source   = "0.0.0.0/0"
    },
    {
      icmp_options {
        "type" = 8
      }

      protocol = 1
      source   = "0.0.0.0/0"
    },
  ]
}

output "OCI-VCN-1-OCID" {value = "${oci_core_vcn.VNC-1.id}"}
output "OCI-SUBNET-1-OCID" {value = "${oci_core_subnet.SubNet-1.id}"}


