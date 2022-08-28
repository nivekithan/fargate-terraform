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

resource "aws_security_group" "allow_all_http" {
    name = "allow_all_http"
    description = "Allow http always"
    vpc_id = aws_vpc.fargte_main.id

    ingress {
        description = "HTTP from everywhere"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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


resource "aws_ecs_cluster" "fargate_terraform" {
    name = "fargate_terraform"
    
}

resource "aws_ecs_task_definition" "nginx" {
    family = "fargate_nginx"
    
 
    container_definitions = jsonencode([
    {
        name = "nginx"
        cpu = 0
        image = "00519828617.dkr.ecr.ap-south-1.amazonaws.com/learn-ecr:0e8c61cbda82524bd4389725b8bd953ac46083e3"
        portMappings = [
            {
                containerPort = 80
                hostPort = 80
                portcol = "tcp"
            }
        ]
        essential = true
    }        
    ])
    execution_role_arn = "arn:aws:iam::100519828617:role/ecsTaskExecutionRole"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 512
    memory = 1024
    runtime_platform {
      cpu_architecture = "X86_64"
      operating_system_family = "LINUX"
    }
}


resource "aws_ecs_service" "fargate_nginx_1" {
    name = "fargate_nginx"
    cluster = aws_ecs_cluster.fargate_terraform.id
    task_definition = aws_ecs_task_definition.nginx.arn
    desired_count = 1
    launch_type = "FARGATE"

    
    network_configuration {
      subnets = [aws_subnet.fargate_public_subnet.id]
      security_groups = [aws_security_group.allow_all_http.id]
    }
    
}