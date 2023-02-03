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

# get default vpc object using this command
#$ terraform state show aws_vpc.myapp-vpc
# subnet will associate automatically in default route table    
resource "aws_default_route_table" "myapp-default-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
     route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-internet-gateway.id
    }
    tags = {
        Name = "${var.env_prefix[0]}-default-rtb"
        environmet = var.env_prefix[1]
    }
}

