#COMPUTE
resource "oci_core_instance" "Kafka-Instance-1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD1 - 1],"name")}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "Kafka-Instance-1"
  shape = "${var.InstanceShape}"
  source_details {
    source_id = "${var.InstanceImageOCID}"
    source_type = "image"
    boot_volume_size_in_gbs = "50"
  }

  create_vnic_details {
    subnet_id = "${oci_core_subnet.KafkaSubNet.id}"
    display_name = "primaryvnic"
    assign_public_ip = true
    hostname_label = "Kafka-Instance-1"
  },

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data = "${base64encode(var.user-data)}"
  }

  timeouts {
    create = "60m"
  }

  connection {
    agent = false
    timeout = "30m"
    host = "${oci_core_instance.Kafka-Instance-1.public_ip}"
    user = "opc"
    private_key = "${var.ssh_private_key}"
  }

  #update SO and configure repositories
 /* provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo /usr/bin/ol_yum_configure.sh"
    ]
  }*/

  #install JAVA
  provisioner "remote-exec" {
    inline = [
      "sudo wget --no-cookies --no-check-certificate --header 'Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie' 'https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz'",
      "sudo tar -xzf jdk-8u201-linux-x64.tar.gz -C /opt/",
      "sudo chown -R root:root /opt/jdk1.8.0_201/",
      "sudo alternatives --install /usr/bin/java java /opt/jdk1.8.0_201/bin/java 1",
      "sudo alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_201/bin/jar 1",
      "sudo alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_201/bin/javac 1",
      "sudo alternatives --set jar /opt/jdk1.8.0_201/bin/jar",
      "sudo alternatives --set javac /opt/jdk1.8.0_201/bin/javac",
      "echo 'export JAVA_HOME=/opt/jdk1.8.0_201' >> ~/.bashrc",
      "echo 'export JRE_HOME=/opt/jdk1.8.0_201/jre' >> ~/.bashrc",
      "echo 'export PATH=$PATH:/opt/jdk1.8.0_201/bin:/opt/jdk1.8.0_201/jre/bin' >> ~/.bashrc",
      "sudo rm jdk-8u201-linux-x64.tar.gz"
    ]
  }

  #install and start Kafka
  provisioner "remote-exec" {
    inline = [
      "wget -O kafka_2.11-2.1.0.tgz https://www-eu.apache.org/dist/kafka/2.1.0/kafka_2.11-2.1.0.tgz",
      "tar -xzf kafka_2.11-2.1.0.tgz",
      "rm kafka_2.11-2.1.0.tgz",
      "mkdir logs",
      "sed -i 's/zookeeper.connect=localhost/zookeeper.connect=${oci_core_instance.Zookeeper-Instance-1.private_ip}/g' kafka_2.11-2.1.0/config/server.properties",
      "nohup kafka_2.11-2.1.0/bin/kafka-server-start.sh kafka_2.11-2.1.0/config/server.properties >> logs/kafka.out &",
      "sudo chmod +x /etc/rc.d/rc.local",
      "echo 'nohup /home/opc/kafka_2.11-2.1.0/bin/kafka-server-start.sh /home/opc/kafka_2.11-2.1.0/config/server.properties >> /home/opc/logs/kafka.out &' | sudo tee --append /etc/rc.local > /dev/null",
      "exit"
    ]
  }
}

output "publicKafkaIP" {value = "${oci_core_instance.Kafka-Instance-1.public_ip}"}
output "privateKafkaIP" {value = "${oci_core_instance.Kafka-Instance-1.private_ip}"}