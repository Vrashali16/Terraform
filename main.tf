#Create 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile="default"
  access_key="ASIAUX5TE2UUCI22S3G4"
  secret_key="0GVO86D+bKrPIHdFCkIzHRrBBPWOMcu4XJz2etAO"
  token="FwoGZXIvYXdzEN7//////////wEaDPB+LbPJJPbFzvKnlSK2AQ5E1uE+tbJZ69QOvMLENSznSHPPRw7w2Gy9WORCSgP5PSQG70+p/moOGA/2Hu2CiUdvvmru4Tan69gaGdveRe4e0/igzSopjYu7mbsisvLAxj/gJ0FuPkFWA49yTYRWe6WAuacD0S87Blnr7I7CEkcTmRp0wC+0dHQqrdgw3X1gu+bgB2Um+/ep4tytQU9ZjL3eUk2XzWkN3SxwE+WDRuoZYKzMGPVephHwbfg9/W2+0wZ6Lo+kKJXBt5EGMi26RloEkAESp1wCSVez/yJCWaGD2ihXnaFFK0XQGNBoDq2zhON1BRCMeun/6tk="
  region="us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]

}


variable "ingressrules" {
 type    = list(number)
 default = [22, 8080]
}


resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}
output "instance_ips" {
  value = aws_instance.jenkins.public_ip
}
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "key-pair"

  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update -qq",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository ppa:deadsnakes/ppa -y",
      "sudo apt install -y python",
      "sudo apt install -y openjdk-11-jdk",
      "sudo apt install jenkins -y",
      "JAVA_HOME=/usr/lib/jvm/openjdk-11",
      "PATH=$PATH:$JAVA_HOME/bin",
      "export PATH",
      "sudo systemctl start jenkins",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("./key-pair.pem")
  }
  tags = {
    "Name"      = "Jenkins_Server"
    "Terraform" = "true"
  }

}
