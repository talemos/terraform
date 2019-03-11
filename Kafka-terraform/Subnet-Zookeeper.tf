#Subnet resource
resource "oci_core_subnet" "ZookeeperSubNet" {
  availability_domain = ""
  cidr_block = "10.10.10.0/24"
  display_name = "ZookeeperSubNet"
  security_list_ids   = ["${oci_core_security_list.SL-Zookeeper.id}"]
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.Kafka-VNC.id}"
  route_table_id = "${oci_core_route_table.RT-Zookeeper.id}"
  dns_label="zookeeper"
}

#Route Table
resource "oci_core_route_table" "RT-Zookeeper" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_vcn.Kafka-VNC.id}"
  display_name = "RT-Zookeeper"
  route_rules {
    destination = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.IG-VNC.id}"
  }
}

#Security List
resource "oci_core_security_list" "SL-Zookeeper" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "SL-Zookeeper"
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
    {
      protocol = "6"
      source = "${oci_core_subnet.KafkaSubNet.cidr_block}"
      tcp_options {
        max = "2181"
        min = "2181"
      }
    }
  ]
}

output "OCI-ZookeeperSubNet-OCID" {value = "${oci_core_subnet.ZookeeperSubNet.id}"}