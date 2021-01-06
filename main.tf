# Which cloud provider is required?
# AWS as this is where we have created our AMIs.

provider "aws" {
    region = var.region

}

module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}


resource "aws_vpc" "VPC-Aminah" {
    cidr_block = "13.0.0.0/16"
    instance_tenancy = "default"
    tags = {
        Name = "eng74-aminah-VPC-terraform"
    }
}

resource "aws_internet_gateway" "igw-Aminah" {
    vpc_id = aws_vpc.VPC-Aminah.id
    tags = {
        Name = "eng74-aminah-igw-terraform"
    }
}

resource "aws_subnet" "subnet_public" {
    vpc_id = aws_vpc.VPC-Aminah.id
    cidr_block = "13.0.1.0/24"
    tags = {
        Name = "eng74-aminah-public-subnet-terraform"
    }
}

resource "aws_subnet" "subnet_private" {
    vpc_id = aws_vpc.VPC-Aminah.id
    cidr_block = "13.0.2.0/24"
    tags = {
        Name = "eng74-aminah-private-subnet-terraform"
    }
}

resource "aws_security_group" "app_sg" {
  name        = "eng74-aminah-app-sg-public"
  description = "Allows traffic to app"
  vpc_id      = aws_vpc.VPC-Aminah.id

  ingress {
    description = "All http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${module.myip.address}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eng74-aminah-app-sg"
  }
}

resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.VPC-Aminah.id
  subnet_ids=[aws_subnet.subnet_public.id]

  egress {
    protocol   = "all"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "${module.myip.address}/32"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "eng74-aminah-nacl-terraform"
  }
}


resource "aws_route_table" "route_table" {
  vpc_id =  aws_vpc.VPC-Aminah.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-Aminah.id
  }

  tags = {
    Name = "eng74-aminah-public-route-terraform"
  }
}



resource "aws_route_table_association" "route_table" {
  route_table_id= aws_route_table.route_table.id
  subnet_id=aws_subnet.subnet_public.id
}


resource "aws_instance" "nodejs_instance-app" {
    ami = var.app_ami
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id=aws_subnet.subnet_public.id
    security_groups=[aws_security_group.app_sg.id]
    tags = {
        Name = "eng74-aminah-nodejs-app-3"
    }
    key_name = var.key_name
}
