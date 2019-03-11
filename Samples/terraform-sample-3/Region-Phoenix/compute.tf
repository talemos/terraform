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

#ATTACH
resource "oci_core_volume_attachment" "BlockAttach-1" {
  attachment_type = "iscsi"
  compartment_id = "${var.compartment_ocid}"
  instance_id = "${oci_core_instance.Instance-1.id}"
  volume_id = "${oci_core_volume.BlockVolume-1.id}"

  connection {
    agent = false
    timeout = "30m"
    host = "${oci_core_instance.Instance-1.public_ip}"
    user = "opc"
    private_key = "${var.ssh_private_key}"
  }

  # register and connect the iSCSI block volume
  provisioner "remote-exec" {
    inline = [
      "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
      "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
      "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l"
    ]
  }

  # initialize partition and file system
  provisioner "remote-exec" {
    inline = [
      "set -x",
      "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
      "export HAS_PARTITION=$(sudo partprobe -d -s /dev/disk/by-path/$${DEVICE_ID} | wc -l)",
      "if [ $HAS_PARTITION -eq 0 ] ; then",
      "  (echo g; echo n; echo ''; echo ''; echo ''; echo w) | sudo fdisk /dev/disk/by-path/$${DEVICE_ID}",
      "  while [[ ! -e /dev/disk/by-path/$${DEVICE_ID}-part1 ]] ; do sleep 1; done",
      "  sudo mkfs.xfs /dev/disk/by-path/$${DEVICE_ID}-part1",
      "fi"
    ]
  }

  # mount the partition
  provisioner "remote-exec" {
    inline = [
      "set -x",
      "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
      "sudo mkdir -p /mnt/vol1",
      "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
      "echo 'UUID='$${UUID}' /mnt/vol1 xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
      "sudo mount -a"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    on_failure = "continue"
    inline = [
      "set -x",
      "export DEVICE_ID=ip-${self.ipv4}:${self.port}-iscsi-${self.iqn}-lun-1",
      "export UUID=$(sudo /usr/sbin/blkid -s UUID -o value /dev/disk/by-path/$${DEVICE_ID}-part1)",
      "sudo umount /mnt/vol1",
      "if [[ $UUID ]] ; then",
      "  sudo sed -i.bak '\\@^UUID='$${UUID}'@d' /etc/fstab",
      "fi",
      "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -u",
      "sudo iscsiadm -m node -o delete -T ${self.iqn} -p ${self.ipv4}:${self.port}"
    ]
  }
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

output "publicIP" {value = "${oci_core_instance.Instance-1.public_ip}"}
output "privateIP" {value = "${oci_core_instance.Instance-1.private_ip}"}