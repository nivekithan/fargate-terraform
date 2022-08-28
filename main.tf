terraform {
 required_providers {
   aws = {
    source = "hashicorp/aws"
    version = "~> 4.0"
   }
 }
}

provider "aws" {
  region = "ap-south-1"
}


resource "aws_vpc" "fargte_main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    "Name" = "fargate_terraform"
  }
}

resource "aws_internet_gateway" "fargate_gateway" {
    vpc_id = aws_vpc.fargte_main.id
    depends_on = [
      aws_vpc.fargte_main
    ]
    tags = {
      "Name" = "fargate_gateway"
    }
}

resource "aws_subnet" "fargate_public_subnet" {

    vpc_id = aws_vpc.fargte_main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    depends_on = [
      aws_vpc.fargte_main
    ]
    tags = {
        Name = "fargate_public_subnet"
    }               
}

resource "aws_route_table" "fargate_public_route_table" {
    vpc_id = aws_vpc.fargte_main.id


    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.fargate_gateway.id
    }

    tags = {
      "Name" = "fargate_public_route_table"
    }
}

resource "aws_route_table_association" "fargate_pub_rt_to_pub_subnet" {
    subnet_id = aws_subnet.fargate_public_subnet.id
    route_table_id = aws_route_table.fargate_public_route_table.id
}

resource "aws_subnet" "fargate_private_subnet_1" {
    vpc_id = aws_vpc.fargte_main.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = false
    depends_on = [
      aws_vpc.fargte_main
    ]

    tags = {
      "Name" = "fargate_private_subnet_1"
    }
}

resource "aws_subnet" "fargate_private_subnet_2" {
    vpc_id = aws_vpc.fargte_main.id
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false
    depends_on = [
      aws_vpc.fargte_main
    ]

    tags = {
      "Name" = "fargate_private_subnet_2"
    }
}


