variable "InstanceImageOCID" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "InstanceShape" {}

variable "DBSize" {
    default = "50" // size in GBs
}

#User Data variable
variable "user-data" {
  default = <<EOF
#!/bin/bash -x
echo '################### userdata begins #####################'
touch ~opc/userdata.`date +%s`.start

# echo '########## yum update ###############'
# yum update -y
touch ~opc/userdata.`date +%s`.finish
echo '################### userdata ends #######################'
EOF
}

#BLOCK RESOURCES
resource "oci_core_volume" "BlockVolume-1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "BlockVolume-1"
  size_in_gbs = "${var.DBSize}"
}

resource "oci_core_volume_attachment" "BlockAttach-1" {
    attachment_type = "iscsi"
    compartment_id = "${var.compartment_ocid}"
    instance_id = "${oci_core_instance.Instance-1.id}"
    volume_id = "${oci_core_volume.BlockVolume-1.id}"
}

#COMPUTE
resource "oci_core_instance" "Instance-1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "Instance-1"
  shape = "${var.InstanceShape}"
  source_details {
    source_id = "${var.InstanceImageOCID}"
    source_type = "image"
    boot_volume_size_in_gbs = "50"
  }

  create_vnic_details {
    subnet_id = "${oci_core_subnet.SubNet-1.id}"
    display_name = "primaryvnic"
    assign_public_ip = true
    hostname_label = "Instance1"
  },

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(var.user-data)}"
  }

  timeouts {
    create = "60m"
  }
}

#Remote Exec Provisioner
resource "null_resource" "remote-exec" {
    depends_on = ["oci_core_instance.Instance-1","oci_core_volume_attachment.BlockAttach-1"]
    provisioner "remote-exec" {
      connection {
        agent = false
        timeout = "30m"
        host = "${oci_core_instance.Instance-1.public_ip}"
        user = "opc"
        private_key = "${var.ssh_private_key}"
    }
      inline = [
        "sudo iscsiadm -m node -o new -T ${oci_core_volume_attachment.BlockAttach-1.iqn} -p ${oci_core_volume_attachment.BlockAttach-1.ipv4}:${oci_core_volume_attachment.BlockAttach-1.port}",
        "sudo iscsiadm -m node -o update -T ${oci_core_volume_attachment.BlockAttach-1.iqn} -n node.startup -v automatic",
        "echo sudo iscsiadm -m node -T ${oci_core_volume_attachment.BlockAttach-1.iqn} -p ${oci_core_volume_attachment.BlockAttach-1.ipv4}:${oci_core_volume_attachment.BlockAttach-1.port} -l >> ~/.bashrc"
      ]
    }
}

output "publicIP" {value = "${oci_core_instance.Instance-1.public_ip}"}
output "privateIP" {value = "${oci_core_instance.Instance-1.private_ip}"}


