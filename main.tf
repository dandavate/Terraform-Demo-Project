#defined providers

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.53.0"
    }
  }
}

#accessing providers
provider "aws" {
    region = "us-east-1"
}

#defined variables
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "myip" {}
variable "instance_type" {}
variable "public_key_location" {}


#creates custome vpc
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix[0]}-vpc"
        environmet = var.env_prefix[1]
    }
}

#Creates subnet-1 inside myapp-vpc
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block[0]
    availability_zone = var.avail_zone[0]  
    tags = {
        Name = "${var.env_prefix[0]}-subnet-1"
        environmet = var.env_prefix[1]
    }
}

# creates internet getway
resource "aws_internet_gateway" "myapp-internet-gateway" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix[0]}-igw"
        environmet = var.env_prefix[1]
    }
}

#Create route table
# internal route will create automatically
# define external route
resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-internet-gateway.id
    }
    tags = {
        Name = "${var.env_prefix[0]}-rtb"
        environmet = var.env_prefix[1]
    }
  
}

# route table association with subnet
resource "aws_route_table_association" "myapp-rtb-association" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

# create security group
# ingress for incomming traffic
# egress for outgoing traffic
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    ingress  {
      cidr_blocks = [var.myip]
      from_port = 22
      protocol = "tcp"
      to_port = 22
    } 
    ingress  {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    } 
    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      protocol = "-1"
      to_port = 0
    }
    tags = {
        Name = "${var.env_prefix[0]}-sg"
        environmet = var.env_prefix[1]
    }
}

# fetch AMI 
data "aws_ami" "latest-ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = [ "amzn2-ami-kernel-*-x86_64-gp2" ]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

# create ssh-key
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
  
}

# create instance
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-ami.id
    instance_type = var.instance_type
    
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]

    availability_zone = var.avail_zone[0]
    associate_public_ip_address = true

    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("user-data-script.sh")
    
    tags = {
         Name = "${var.env_prefix[0]}-server"
         environmet = var.env_prefix[1]
    }
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
