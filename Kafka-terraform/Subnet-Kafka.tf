#Subnet resource
resource "oci_core_subnet" "KafkaSubNet" {
  availability_domain = ""
  cidr_block = "10.10.20.0/24"
  display_name = "KafkaSubNet"
  security_list_ids   = ["${oci_core_security_list.SL-Kafka.id}"]
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.Kafka-VNC.id}"
  route_table_id = "${oci_core_route_table.RT-Kafka.id}"
  dns_label="kafkasubnet"
}

#Route Table
resource "oci_core_route_table" "RT-Kafka" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.Kafka-VNC.id}"
  display_name = "RT-Kafka"
  route_rules {
    destination = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.IG-VNC.id}"
  }
}

#Security List
resource "oci_core_security_list" "SL-Kafka" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "SL-Kafka"
  vcn_id         = "${oci_core_vcn.Kafka-VNC.id}"

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

output "OCI-KafkaSubNet-OCID" {value = "${oci_core_subnet.KafkaSubNet.id}"}