// terraform script

locals {
ami_id = "ami-080e1f13689e07408"
vpc_id = "vpc-00ad6a223561e5e0d"
ssh_user = "ubuntu"
key_name = "keypair"
private_key_path = "/home/labsuser/ansible/keypair"
}
// provider details

provider "aws" {
    region = "us-east-1" 
}

// aws security resource group

resource "aws_security_group" "projectaccess" {
    name = "projectaccess"
    vpc_id = local.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

     ingress {
        from_port = 80
        to_port   = 80
        protocol =  "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }      

      egress {
         from_port = 0
         to_port = 0
         protocol = "-1"
         cidr_blocks = ["0.0.0.0/0"]
         }
}

// aws instance resource block

resource "aws_instance" "project1" {
          ami = local.ami_id
          instance_type   = "t2.micro"
          associate_public_ip_address = true
          vpc_security_group_ids = [aws_security_group.projectaccess.id] 
          key_name = local.key_name
          tags= {
             name= "project1"
             }
#  SSH Connection block which will be used by the provisioners - remote-exec
  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }         

// Remote-exec Provisioner Block - wait for SSH connection
  provisioner "remote-exec" {
    inline = [
      "echo 'wait for SSH connection to be ready…'",
      "touch /home/ubuntu/demo-file-from-terraform.txt"
   ]
  }

//Local-exec Provisioner Block - create an Ansible Dynamic Inventory
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts"
  }


// Local-exec Provisioner Block - execute an ansible playbook
  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} main.yml"
  }

// Remote-exec Provisioner Block - wait for SSH connection
  provisioner "remote-exec" {
    inline = [
       "sudo docker run -itd --name tomcat_container -p:80:8080 -v /home/ubuntu/sample.war:/usr/local/tomcat/webapps/sample.war tomcat:latest"
   ]
  }
 }

// aws-instance private-ip_address

output "private_ips" {
description = "List of private IP addresses assigned to instances"
value       = aws_instance.project1.*.private_ip
           
}

// aws-instance public-ip_address

output "public_ips" {
description = "List of private IP addresses assigned to instances"
value       = aws_instance.project1.*.public_ip

}

