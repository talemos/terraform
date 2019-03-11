#Netework resource
resource "oci_core_vcn" "Kafka-VNC" {
   cidr_block = "10.10.0.0/16"
   compartment_id = "${var.compartment_ocid}"
   display_name = "Kafka-VNC"
   dns_label ="kafkavnc"
}

#Internet Gateway
resource "oci_core_internet_gateway" "IG-VNC" {
  compartment_id = "${var.compartment_ocid}"
  display_name = "IG-VNC"
  vcn_id = "${oci_core_vcn.Kafka-VNC.id}"
}

output "OCI-Kafka-VNC-OCID" {value = "${oci_core_vcn.Kafka-VNC.id}"}


