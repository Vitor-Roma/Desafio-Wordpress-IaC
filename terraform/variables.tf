variable "region" {
  default =  "us-east-1"
}

variable "profile" {
  default = "vitor"
}

variable "name_security_group" {
  default = "allow_ssh"
}

variable "vpn_id_security_group" {
  default = "vpc-07f3b92c3aad33686"
}

variable "ami_aws_instance" {
  default = "ami-04505e74c0741db8d"
}

variable "type_aws_instance" {
  default = "t2.micro"
}

variable "subnet_id_aws_instance" {
  default = "subnet-0e41365f1eeee819f"
}

variable "key_aws_instance" {
  default = "Desafio_terraform"
}

variable "auto_scale_ami" {
  default = "ami-0799c875671835f12"
}